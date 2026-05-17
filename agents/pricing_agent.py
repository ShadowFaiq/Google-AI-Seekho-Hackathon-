def calculate_price(provider_rate: float, distance_km: float, urgency: str, is_emergency: bool = False, complexity: str = 'basic'):
    """
    Calculates price using the formula:
    Base rate + distance surcharge + urgency multiplier + job complexity - loyalty discount
    """
    # 1. Base Rate
    base_rate = provider_rate
    
    # 2. Distance Surcharge (e.g., 40 PKR per km)
    distance_surcharge = distance_km * 40
    
    # 3. Urgency Multiplier
    urgency_multiplier = 1.0
    if is_emergency:
        urgency_multiplier = 1.5
    elif urgency == 'high':
        urgency_multiplier = 1.3
    
    # 4. Job Complexity
    complexity_premium = 0
    if complexity == 'intermediate':
        complexity_premium = 300
    elif complexity == 'complex':
        complexity_premium = 800
        
    # 5. Loyalty Discount (Mocked to 0 for now)
    loyalty_discount = 0
    
    total = (base_rate * urgency_multiplier) + distance_surcharge + complexity_premium - loyalty_discount
    
    return {
        "base_rate": base_rate,
        "distance_surcharge": round(distance_surcharge, 2),
        "urgency_multiplier": urgency_multiplier,
        "complexity_premium": complexity_premium,
        "loyalty_discount": loyalty_discount,
        "total_price": round(total, 2)
    }
