import math

def calculate_dumb_distance(loc1, loc2):
    dx = (loc1.get('lng',0) - loc2.get('lng',0)) * 111
    dy = (loc1.get('lat',0) - loc2.get('lat',0)) * 111
    return math.sqrt(dx*dx + dy*dy)

class BaselineEngine:
    def __init__(self, providers: list, user_location: dict):
        self.providers = providers
        self.user_location = user_location
        
    def calculate_baseline(self) -> list:
        baseline = []
        for provider in self.providers:
            dist_km = calculate_dumb_distance(provider.get('location', self.user_location), self.user_location)
            rate = provider.get('base_hourly_rate', 1000)
            
            # Simple formula: 80% distance, 20% price. Lower is better.
            # Normalize naive
            dist_score = min(dist_km, 50) / 50.0 
            rate_score = min(rate, 5000) / 5000.0
            
            # dumb baseline score = 0.8*distance + 0.2*price
            baseline_score = (0.8 * dist_score) + (0.2 * rate_score)
            
            baseline.append({
                "provider_id": provider.get("id"),
                "provider_name": provider.get("name"),
                "distance_km": round(dist_km, 1),
                "baseline_score": round(baseline_score, 3),
                "eta_mins": round((dist_km / 40.0) * 60, 1),
                "cancellation_rate": provider.get("cancellation_rate", 0)
            })
            
        # Sort ascending (lower score is better for this naive metric)
        baseline.sort(key=lambda x: x['baseline_score'])
        return baseline
