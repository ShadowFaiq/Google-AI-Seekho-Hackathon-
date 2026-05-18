import math
import os
import googlemaps

# Initialize Google Maps client if key exists
gmaps = None
if os.getenv("GOOGLE_MAPS_API_KEY"):
    gmaps = googlemaps.Client(key=os.getenv("GOOGLE_MAPS_API_KEY"))

def calculate_distance(loc1, loc2):
    if gmaps:
        try:
            origin = (loc1['lat'], loc1['lng'])
            dest = (loc2['lat'], loc2['lng'])
            result = gmaps.distance_matrix(origin, dest, mode="driving")
            
            if result['rows'][0]['elements'][0]['status'] == 'OK':
                element = result['rows'][0]['elements'][0]
                dist_km = element['distance']['value'] / 1000.0
                duration_mins = element['duration']['value'] / 60.0
                return dist_km, duration_mins
        except Exception as e:
            pass
            
    # Fallback Euclidean calculation
    dx = (loc1.get('lng',0) - loc2.get('lng',0)) * 111
    dy = (loc1.get('lat',0) - loc2.get('lat',0)) * 111
    dist_km = math.sqrt(dx*dx + dy*dy)
    duration_mins = (dist_km / 40.0) * 60
    return dist_km, duration_mins

def get_baseline_ranking(providers, user_location):
    baseline = []
    for provider in providers:
        dist_km, duration_mins = calculate_distance(provider.get('location', user_location), user_location)
        baseline.append({
            "provider": provider,
            "distance_km": round(dist_km, 1),
            "eta_mins": round(duration_mins, 1)
        })
    baseline.sort(key=lambda x: x['distance_km'])
    return baseline

class RankingAgent:
    name = "RankingAgent"

    def __init__(self, ctx: dict):
        self.ctx = ctx

    async def run(self) -> dict:
        providers = self.ctx.get("providers", [])
        intent = self.ctx.get("intent", {})
        
        # User loc now comes from GeoNormalizationAgent
        user_loc = self.ctx.get("normalized_location", intent.get("user_location", {"lat": 31.4697, "lng": 74.4012}))
        is_emergency = self.ctx.get("is_emergency", False)
        
        required_subtype = intent.get("service_subtype", "").lower()
        budget = intent.get("budget")
        
        # Determine max/min for normalization
        max_eta = 1.0 # prevent div by zero
        eta_min = 9999.0
        max_rate = 1.0
        
        for provider in providers:
            dist_km, duration_mins = calculate_distance(provider.get('location', user_loc), user_loc)
            provider["eta_mins"] = duration_mins
            provider["dist_km"] = dist_km
            if duration_mins > max_eta: max_eta = duration_mins
            if duration_mins < eta_min: eta_min = duration_mins
            rate = provider.get('base_hourly_rate', 1000)
            if rate > max_rate: max_rate = rate

        WEIGHTS = {
            "eta": 0.15,
            "rating": 0.15,
            "cancel_rate": 0.15,
            "on_time": 0.10,
            "recency": 0.10,
            "specialization": 0.10,
            "rate": 0.05,
            "pref_history": 0.05,
            "workload": 0.10,
            "budget_fit": 0.05
        }

        if is_emergency:
            # Emergency override: eta -> 0.50, others scaled to sum 0.50
            scale = 0.50 / 0.85 # sum of others is 0.85
            WEIGHTS["eta"] = 0.50
            for k in WEIGHTS:
                if k != "eta":
                    WEIGHTS[k] = WEIGHTS[k] * scale

        ranked = []
        for provider in providers:
            # Normalizations
            eta_score = 1.0 - (provider["eta_mins"] / max_eta)
            rating_score = provider.get("rating", 4.0) / 5.0
            
            cancel_rate = provider.get("cancellation_rate", 0) / 100.0 # assuming percentage
            cancel_score = 1.0 - cancel_rate
            
            on_time_score = provider.get("on_time_score", 80) / 100.0 # assuming percentage
            
            days_since_review = provider.get("last_review_days_ago", 30)
            recency_score = math.exp(-days_since_review / 30.0)
            
            # Specialization
            prov_specialty = provider.get("specialty", "").lower()
            specialization_score = 0.0
            if required_subtype and prov_specialty:
                if required_subtype == prov_specialty:
                    specialization_score = 1.0
                elif required_subtype in prov_specialty or prov_specialty in required_subtype:
                    specialization_score = 0.5
                    
            rate_score = 1.0 - (provider.get("base_hourly_rate", 1000) / max_rate)
            
            pref_score = 1.0 if provider.get("user_rated_before", False) else 0.0
            
            # FACTOR 9: Workload Balancing
            active_jobs = provider.get("active_jobs", 0)
            future_bookings = len(provider.get("future_bookings", []))
            max_jobs = provider.get("max_capacity", 5) # Assuming 5 jobs a day is max
            workload_score = max(0.0, 1.0 - ((active_jobs + future_bookings) / max(max_jobs, 1)))
            
            # FACTOR 10: Budget Fit
            provider_rate = provider.get("base_hourly_rate", 1000)
            if budget and budget > 0:
                diff = provider_rate - budget
                if diff <= 0:
                    budget_fit_score = 1.0 # Within budget
                else:
                    budget_fit_score = max(0.0, 1.0 - (diff / budget))
            else:
                budget_fit_score = 1.0 # Ignore if no budget specified
            
            final_score = (
                (eta_score * WEIGHTS["eta"]) +
                (rating_score * WEIGHTS["rating"]) +
                (cancel_score * WEIGHTS["cancel_rate"]) +
                (on_time_score * WEIGHTS["on_time"]) +
                (recency_score * WEIGHTS["recency"]) +
                (specialization_score * WEIGHTS["specialization"]) +
                (rate_score * WEIGHTS["rate"]) +
                (pref_score * WEIGHTS["pref_history"]) +
                (workload_score * WEIGHTS["workload"]) +
                (budget_fit_score * WEIGHTS["budget_fit"])
            )
            
            ranked.append({
                "provider": provider,
                "distance_km": round(provider["dist_km"], 1),
                "eta_mins": round(provider["eta_mins"], 1),
                "score": round(final_score, 3),
                "breakdown": {
                    "eta_score": round(eta_score, 2),
                    "trust_score": round(rating_score, 2),
                    "workload_score": round(workload_score, 2),
                    "budget_fit_score": round(budget_fit_score, 2)
                }
            })
            
        ranked.sort(key=lambda x: x['score'], reverse=True)
        self.ctx["ranked_providers"] = ranked
        
        if not ranked:
            self.ctx["halt"] = True
            
        return self.ctx
