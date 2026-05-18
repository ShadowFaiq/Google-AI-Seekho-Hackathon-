import os
import json
from google import genai
from google.genai import types

try:
    client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
except Exception as e:
    client = None

class GeoNormalizationAgent:
    name = "GeoNormalizationAgent"

    def __init__(self, ctx: dict):
        self.ctx = ctx

    async def run(self) -> dict:
        intent = self.ctx.get("intent", {})
        raw_location = intent.get("raw_location_string", "")
        
        # If intent didn't extract raw location but did user_input
        if not raw_location:
            raw_location = self.ctx.get("user_input", "")

        if not client or not os.getenv("GEMINI_API_KEY") or os.getenv("GEMINI_API_KEY") == "your_actual_key_here":
            # Mock fallback logic
            if "g13" in raw_location.lower() or "g-13" in raw_location.lower() or "جی تیرہ" in raw_location:
                normalized = {"address": "G-13, Islamabad", "lat": 33.6393, "lng": 72.9696, "location_confidence": 0.95}
            elif "dha" in raw_location.lower():
                # DHA is ambiguous — exists in Lahore, Islamabad, Karachi
                normalized = {"address": "DHA", "lat": 0, "lng": 0, "location_confidence": 0.40, "clarification_needed": True}
            elif "model town" in raw_location.lower():
                # Model Town exists in Lahore and other cities
                normalized = {"address": "Model Town", "lat": 0, "lng": 0, "location_confidence": 0.50, "clarification_needed": True}
            elif "satellite town" in raw_location.lower():
                normalized = {"address": "Satellite Town", "lat": 0, "lng": 0, "location_confidence": 0.45, "clarification_needed": True}
            else:
                normalized = {"address": "Central, Unknown", "lat": 0, "lng": 0, "location_confidence": 0.60}
        else:
            prompt = f"""
            You are the GeoNormalization Agent. Normalize the following raw user input which might contain a location in Urdu, Roman Urdu, or English.
            
            User Input: "{raw_location}"
            
            Output strictly a JSON object with:
            - address: Standardized full address string (e.g. "G-13, Islamabad, Pakistan")
            - lat: Float latitude (approximate is fine for mock)
            - lng: Float longitude
            """
            try:
                response = client.models.generate_content(
                    model='gemini-2.5-flash',
                    contents=prompt,
                    config=types.GenerateContentConfig(response_mime_type="application/json")
                )
                normalized = json.loads(response.text)
            except Exception as e:
                normalized = {"address": "Unknown", "lat": 0, "lng": 0, "clarification_needed": False}
                
        # Check if the location is ambiguous — confidence threshold is 0.75
        location_confidence = normalized.get("location_confidence", 0.9)
        is_ambiguous = normalized.get("clarification_needed", False) or location_confidence < 0.75

        if is_ambiguous:
            address = normalized.get("address", "this location")
            self.ctx["halt"] = True
            self.ctx["error_msg"] = f"Location '{address}' is ambiguous. Could you clarify which city? (e.g. DHA Lahore, DHA Islamabad, or DHA Karachi)"
                
        # Inject back into intent for downstream agents
        intent["user_location"] = normalized
        self.ctx["intent"] = intent
        self.ctx["normalized_location"] = normalized
        return self.ctx
