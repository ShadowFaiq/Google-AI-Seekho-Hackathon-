from database.mock_firestore import db

def book_service(req_id: str, user_id: str, provider: dict, price_breakdown: dict, time_preference: str):
    """
    Simulates booking confirmation, provider assignment, and notification scheduling.
    """
    # Pick a slot (mock logic)
    slots = provider.get('slots', {})
    available_slots = slots.get('tomorrow', [])
    if not available_slots:
        available_slots = slots.get('today', ["02:00 PM"]) # fallback
        
    selected_slot = available_slots[0] if available_slots else "12:00 PM"
    
    # Create booking in DB
    booking_id = db.create_booking(
        req_id=req_id,
        user_id=user_id,
        provider_id=provider['provider_id'],
        price_breakdown=price_breakdown,
        slot=selected_slot
    )
    
    # Simulate notification (Notification Agent)
    notification = {
        "type": "whatsapp_sms_simulation",
        "to": provider['phone'],
        "message": f"New booking: {provider['service_category']} at {selected_slot}. Booking ID: {booking_id}"
    }
    
    return booking_id, selected_slot, notification
