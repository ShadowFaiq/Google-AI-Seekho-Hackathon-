import math

def calculate_distance(loc1, loc2):
    """Mock distance calculation between two lat/lng points in km"""
    # Simple Euclidean distance scaled to approximate km for demo
    # 1 degree is roughly 111km
    dx = (loc1['lng'] - loc2['lng']) * 111
    dy = (loc1['lat'] - loc2['lat']) * 111
    return math.sqrt(dx*dx + dy*dy)

def rank_providers(providers, user_location, is_emergency=False):
    """
    Ranks providers using a 6+ factor matrix:
    - Distance / Travel Time
    - Trust Score (includes ratings, reviews, recency, cancellation rate, completion rate)
    - Price
    
    If is_emergency is True, Distance is heavily prioritized.
    """
    ranked = []
    for provider in providers:
        dist_km = calculate_distance(provider['location'], user_location)
        metrics = provider['metrics']
        
        # Factor 1 & 2: Distance Score (0-100, closer is better)
        # Assuming max reasonable distance is 20km
        dist_score = max(0, 100 - (dist_km * 5))
        
        # Factor 3, 4, 5, 6: Trust Score encapsulates Rating, Recency, Cancellation, On-Time
        trust_score = metrics['trust_score']
        
        # Factor 7: Price Score (Lower is better, normalized around 1500 PKR)
        price_score = max(0, 100 - ((provider['base_hourly_rate'] - 1000) / 10))

        if is_emergency:
            # Emergency weighting: Distance is critical
            final_score = (dist_score * 0.7) + (trust_score * 0.2) + (price_score * 0.1)
        else:
            # Normal weighting
            final_score = (dist_score * 0.25) + (trust_score * 0.5) + (price_score * 0.25)
            
        ranked.append({
            "provider": provider,
            "distance_km": round(dist_km, 1),
            "score": round(final_score, 1),
            "breakdown": {
                "distance_score": round(dist_score, 1),
                "trust_score": trust_score,
                "price_score": round(price_score, 1)
            }
        })
        
    # Sort by score descending
    ranked.sort(key=lambda x: x['score'], reverse=True)
    return ranked
