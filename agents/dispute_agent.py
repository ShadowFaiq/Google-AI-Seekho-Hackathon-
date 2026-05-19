from database.firebase_client import db
import os
import json
from google import genai
from google.genai import types

from agents.llm_client import call_llm

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
        
        has_gemini = os.getenv("GEMINI_API_KEY") and os.getenv("GEMINI_API_KEY") != "your_actual_key_here"
        has_openai = os.getenv("OPENAI_API_KEY") and os.getenv("OPENAI_API_KEY") != "your_openai_key_here"
        
        if not (has_gemini or has_openai):
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
                response_text = call_llm(prompt, json_mode=True)
                resolution = json.loads(response_text)
            except Exception as e:
                print(f"LLM API Error in DisputeAgent: {e}. Falling back to default refund.")
                resolution = {
                    "resolution_status": "refund_approved",
                    "suggested_refund": max(0.0, actual_charge - original_quote),
                    "reasoning": "Arbitration fallback: Automatically approved refund for the price difference due to transient connection issue.",
                    "requires_human": False
                }

        resolution["original_quote"] = original_quote
        resolution["actual_charge"] = actual_charge
        
        # MISSING WRITE-BACK LOGIC
        if resolution.get("resolution_status") == "refund_approved":
            db.increment_provider_strikes(provider_id)
            resolution["strike_issued"] = True
            
        self.ctx["dispute_resolution"] = resolution
        return self.ctx
