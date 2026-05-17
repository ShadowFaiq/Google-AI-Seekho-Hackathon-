from database.mock_firestore import db
from agents.intent_agent import client
from google.genai import types
import json

def handle_dispute(booking_id: str, actual_charge: float, complaint_text: str):
    """
    Handles a dispute by evaluating the original quote vs the actual charge and the user complaint.
    Returns a suggested refund or arbitration result.
    """
    booking = db.bookings.get(booking_id)
    if not booking:
        return {"error": "Booking not found"}
        
    original_quote = booking['price_breakdown']['total_price']
    
    if not client:
        # Mock logic
        diff = actual_charge - original_quote
        if diff > 0:
            suggested_refund = diff * 0.8 # Refund 80% of overcharge
            return {
                "original_quote": original_quote,
                "actual_charge": actual_charge,
                "difference": diff,
                "suggested_refund": round(suggested_refund, 2),
                "resolution_reasoning": "Standard arbitration applied due to overcharging.",
                "escalate_to_human": False
            }
        return {"error": "No overcharge detected"}
        
    prompt = f"""
    You are the Auto Dispute Resolution Agent for KaamConnect.
    
    A user has filed a complaint: "{complaint_text}"
    Original AI Quote: {original_quote} PKR
    Actual Amount Charged by Provider: {actual_charge} PKR
    Difference: {actual_charge - original_quote} PKR
    
    Evaluate the fairness of this dispute. Provide a suggested refund amount (if any) and your reasoning.
    Return ONLY JSON with these keys:
    - suggested_refund (float)
    - resolution_reasoning (string)
    - escalate_to_human (boolean)
    """
    
    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
            )
        )
        result = json.loads(response.text)
        result["original_quote"] = original_quote
        result["actual_charge"] = actual_charge
        result["difference"] = actual_charge - original_quote
        return result
    except Exception as e:
        return {"error": str(e)}
