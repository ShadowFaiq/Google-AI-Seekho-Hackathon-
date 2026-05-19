from database.firebase_client import db
import os
import json
from google import genai
from google.genai import types

try:
    client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
except Exception as e:
    client = None

class DisputeAgent:
    name = "DisputeAgent"

    def __init__(self, ctx: dict):
        self.ctx = ctx

    async def run(self) -> dict:
        dispute_text = self.ctx.get("user_input", "Low rating given. Provider overcharged.")
        
        price_breakdown = self.ctx.get("price_breakdown", {})
        original_quote = price_breakdown.get("total_price", 1000)
        actual_charge = original_quote + 500 # Simulate an overcharge
        
        ranked_providers = self.ctx.get("ranked_providers", [])
        if not ranked_providers:
            self.ctx["halt"] = True
            return self.ctx
            
        provider_id = ranked_providers[0]["provider"].get("id", "prov_1")
        
        if not client or not os.getenv("GEMINI_API_KEY") or os.getenv("GEMINI_API_KEY") == "your_actual_key_here":
            resolution = {
                "resolution_status": "refund_approved",
                "suggested_refund": actual_charge - original_quote,
                "reasoning": "Fallback: Automatically refunding the difference due to lack of API connectivity.",
                "requires_human": False
            }
        else:
            prompt = f"""
            You are the Dispute Agent for KaamConnect.
            A user has filed a complaint regarding overcharging.
            
            Complaint Text: "{dispute_text}"
            Original AI Quote: {original_quote} PKR
            Actual Amount Charged by Provider: {actual_charge} PKR
            
            Determine a fair resolution. Provide the result strictly in JSON format with these fields:
            - resolution_status: 'refund_approved', 'claim_denied', or 'escalated'
            - suggested_refund: Numeric value in PKR. 0 if denied.
            - reasoning: A brief explanation for the decision.
            - requires_human: boolean. True if the situation is complex or aggressive.
            """
            try:
                response = await client.aio.models.generate_content(
                    model='gemini-2.5-flash',
                    contents=prompt,
                    config=types.GenerateContentConfig(response_mime_type="application/json")
                )
                resolution = json.loads(response.text)
            except Exception as e:
                resolution = {
                    "resolution_status": "escalated",
                    "suggested_refund": 0,
                    "reasoning": "System error during arbitration.",
                    "requires_human": True
                }

        resolution["original_quote"] = original_quote
        resolution["actual_charge"] = actual_charge
        
        # MISSING WRITE-BACK LOGIC
        if resolution.get("resolution_status") == "refund_approved":
            db.increment_provider_strikes(provider_id)
            resolution["strike_issued"] = True
            
        self.ctx["dispute_resolution"] = resolution
        return self.ctx
