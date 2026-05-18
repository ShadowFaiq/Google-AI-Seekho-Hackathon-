from database.firebase_client import db

# Ambiguous location areas that are known to exist in multiple cities
AMBIGUOUS_AREAS = ["dha", "model town", "satellite town", "cantt", "gulberg"]

class DiscoveryAgent:
    name = "DiscoveryAgent"

    def __init__(self, ctx: dict):
        self.ctx = ctx

    def _filter_by_radius(self, all_providers, radius_km):
        """Mock spatial filter — in production this would use Firestore geo-queries."""
        if radius_km <= 5:
            return [p for p in all_providers if p.get("id") in ["prov_1", "prov_2"]]
        elif radius_km <= 10:
            return all_providers  # 10km gets all
        else:
            return all_providers  # nearby city fallback gets all too

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
                self.ctx["recovery_action"] = "expand_radius_10km"
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
