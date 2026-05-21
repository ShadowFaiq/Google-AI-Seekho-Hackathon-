import os
import json
from google import genai
from google.genai import types

# Initialize Gemini Client
try:
    client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
except Exception as e:
    print(f"Warning: Could not initialize Gemini Client. Make sure GEMINI_API_KEY is set. Error: {e}")
    client = None

class IntentAgent:
    name = "IntentAgent"

    def __init__(self, ctx: dict):
        self.ctx = ctx

    async def run(self) -> dict:
        text = self.ctx.get("user_input", "")
        
        # Fallback mock for testing without API key
        if not client or not os.getenv("GEMINI_API_KEY") or os.getenv("GEMINI_API_KEY") == "your_actual_key_here":
            confidence = 0.95 if "ac" in text.lower() else 0.5
            intent = {
                "service_type": "ac_repair" if "ac" in text.lower() else "general",
                "service_subtype": "split_ac",
                "urgency": "emergency" if "short circuit" in text.lower() else ("urgent" if "jaldi" in text.lower() else "normal"),
                "preferred_time": "tomorrow morning",
                "raw_location_string": "G-13" if "g-13" in text.lower() else None,
                "budget": 3000 if "3000" in text else None,
                "confidence_breakdown": {"intent": 0.9, "location": 0.8, "time": 0.9, "service": 0.95},
                "clarification_needed": confidence < 0.75,
                "clarification_question": "Kya aap thora wazeh kar saktay hain?" if confidence < 0.75 else None
            }
        else:
            prompt = f"""
            You are the Intent Agent for KaamConnect, an autonomous service OS in Pakistan.
            Analyze the following user request which may be in Urdu, Roman Urdu, or English.
            
            Request: "{text}"
            
            Extract the following information and return ONLY a valid JSON object matching this schema:
            {{
                "service_type": str,          # e.g. "ac_repair"
                "service_subtype": str,       # e.g. "split_ac"
                "urgency": "normal" | "urgent" | "emergency",
                "preferred_time": str | null,
                "raw_location_string": str | null,
                "budget": int | null,
                "confidence_breakdown": {{"intent": float, "location": float, "time": float, "service": float}},
                "clarification_needed": bool,
                "clarification_question": str | null # Roman Urdu preferred
            }}
            """
            try:
                response = await client.aio.models.generate_content(
                    model='gemini-2.5-flash',
                    contents=prompt,
                    config=types.GenerateContentConfig(response_mime_type="application/json")
                )
                intent = json.loads(response.text)
                # Fill missing schema fields just in case
                if "confidence_breakdown" not in intent:
                    intent["confidence_breakdown"] = {"intent": 0.5, "location": 0.5, "time": 0.5, "service": 0.5}
            except Exception as e:
                print(f"Gemini API Error: {e}")
                intent = {"confidence_breakdown": {"intent": 0}, "error": str(e), "clarification_needed": True, "clarification_question": "System error. Please try again."}

        self.ctx["intent"] = intent
        self.ctx["is_emergency"] = (intent.get("urgency") == "emergency")
        
        # Calculate overall confidence
        avg_conf = sum(intent.get("confidence_breakdown", {}).values()) / 4.0 if intent.get("confidence_breakdown") else 0
        
        if avg_conf < 0.75 or intent.get("clarification_needed"):
            self.ctx["halt"] = True
            
        return self.ctx
