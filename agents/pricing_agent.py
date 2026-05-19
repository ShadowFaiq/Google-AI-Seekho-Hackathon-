class PricingAgent:
    name = "PricingAgent"

    def __init__(self, ctx: dict):
        self.ctx = ctx

    async def run(self) -> dict:
        ranked_providers = self.ctx.get("ranked_providers", [])
        if not ranked_providers:
            self.ctx["halt"] = True
            return self.ctx
            
        top_provider_entry = ranked_providers[0]
        provider = top_provider_entry["provider"]
        
        provider_rate = provider.get("base_hourly_rate", 1000)
        distance_km = top_provider_entry["distance_km"]
        
        intent = self.ctx.get("intent", {})
        urgency = intent.get("urgency", "normal")
        is_emergency = self.ctx.get("is_emergency", False)
        
        # Complexity (Defaulting to intermediate for mock)
        complexity = intent.get("complexity", "intermediate")
        
        # Base Rate
        base_rate = provider_rate
        
        # Distance Surcharge (40 PKR per km)
        distance_surcharge = distance_km * 40
        
        # Urgency Multiplier (same day is 1.3x, next day is 1.0x)
        urgency_multiplier = 1.0
        if is_emergency:
            urgency_multiplier = 1.5
        elif urgency == 'urgent' or intent.get("preferred_time", "").lower() == "today":
            urgency_multiplier = 1.3
            
        # Job Complexity Premium
        complexity_premium = 0
        if complexity == 'intermediate':
            complexity_premium = 300
        elif complexity == 'complex':
            complexity_premium = 800
            
        # Loyalty Discount (Mocking a return user discount)
        loyalty_discount = 150 if self.ctx.get("user_id") != "new_user" else 0
            
        total = (base_rate * urgency_multiplier) + distance_surcharge + complexity_premium - loyalty_discount
        
        # InDrive Bidding System Bounds
        suggested_price = round(total, 2)
        floor_price = round(suggested_price * 0.8, 2)  # User cannot go below 80% of calculated price
        ceiling_price = round(suggested_price * 1.5, 2) # Providers cannot ask more than 150%

        price_breakdown = {
            "base_rate": base_rate,
            "distance_surcharge": round(distance_surcharge, 2),
            "urgency_multiplier": urgency_multiplier,
            "complexity_premium": complexity_premium,
            "loyalty_discount": loyalty_discount,
            "suggested_price": suggested_price,
            "floor_price": floor_price,
            "ceiling_price": ceiling_price
        }
        
        self.ctx["price_breakdown"] = price_breakdown
        
        # Halt the pipeline here so the user can review prices and place a bid
        self.ctx["halt"] = True
        self.ctx["bidding_status"] = "WAITING_FOR_USER_BID"
        return self.ctx
