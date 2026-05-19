from database.firebase_client import db

# Ambiguous location areas that are known to exist in multiple cities
AMBIGUOUS_AREAS = ["dha", "model town", "satellite town", "cantt", "gulberg"]

class DiscoveryAgent:
    name = "DiscoveryAgent"

    def __init__(self, ctx: dict):
        self.ctx = ctx

    def _calculate_distance(self, loc1, loc2):
        import math
        dx = (loc1.get('lng', 0) - loc2.get('lng', 0)) * 111
        dy = (loc1.get('lat', 0) - loc2.get('lat', 0)) * 111
        return math.sqrt(dx*dx + dy*dy)

    def _filter_by_radius(self, all_providers, radius_km):
        """Dynamic spatial filter calculating distance using latitude/longitude."""
        intent = self.ctx.get("intent", {})
        user_loc = self.ctx.get("normalized_location", intent.get("user_location", {"lat": 31.4697, "lng": 74.4012}))
        
        filtered = []
        for p in all_providers:
            p_loc = p.get("location")
            if not p_loc or not isinstance(p_loc, dict):
                continue
            dist = self._calculate_distance(p_loc, user_loc)
            if dist <= radius_km:
                filtered.append(p)
        return filtered

    async def run(self) -> dict:
        intent = self.ctx.get("intent", {})
        service_category = intent.get("service_type", "general")
        radius_km = self.ctx.get("discovery_radius_km", 5)

        # db.get_providers_by_category already filters out strikes >= 2
        all_providers = db.get_providers_by_category(service_category)
        providers = self._filter_by_radius(all_providers, radius_km)

        self.ctx["providers"] = providers

        if not providers:
            # Determine which recovery step we are on
            recovery_step = self.ctx.get("discovery_recovery_step", 0)
            recovery_step += 1
            self.ctx["discovery_recovery_step"] = recovery_step

            if recovery_step == 1:
                # Step 1: Expand radius to 10km
                self.ctx["discovery_radius_km"] = 10
                self.ctx["recovery_triggered"] = True
                self.ctx["recovery_action"] = "expand_radius"
                self.ctx["error_msg"] = "No providers in 5km. Expanding search to 10km..."

            elif recovery_step == 2:
                # Step 2: Offer a later time slot today
                self.ctx["recovery_triggered"] = True
                self.ctx["recovery_action"] = "offer_later_slot"
                self.ctx["error_msg"] = "No providers available now. Would you like to book for later today?"

            elif recovery_step == 3:
                # Step 3: Offer nearest available city
                self.ctx["recovery_triggered"] = True
                self.ctx["recovery_action"] = "offer_nearby_city"
                self.ctx["error_msg"] = "No providers in your city. Checking nearest available city..."

            else:
                # Step 4: Recommend next day — final fallback
                self.ctx["recovery_triggered"] = False
                self.ctx["halt"] = True
                self.ctx["error_msg"] = (
                    f"No '{service_category}' providers available today or nearby. "
                    "Would you like to schedule for tomorrow?"
                )

        return self.ctx
