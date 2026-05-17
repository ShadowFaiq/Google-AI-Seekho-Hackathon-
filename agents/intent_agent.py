import os
import json
from google import genai
from google.genai import types

# Ensure you have set the GEMINI_API_KEY environment variable.
# For the hackathon, we will instantiate the client.
try:
    client = genai.Client()
except Exception as e:
    print(f"Warning: Could not initialize Gemini Client. Make sure GEMINI_API_KEY is set. Error: {e}")
    client = None

def parse_intent(text: str) -> dict:
    """
    Takes a natural language request in Urdu, Roman Urdu, or English.
    Extracts: service_category, urgency (low/medium/high), time_preference, location, budget_sensitivity.
    Also detects emergency keywords for the SOS feature.
    """
    if not client:
        # Fallback mock for testing without API key
        if "ac" in text.lower():
            return {
                "service_category": "ac_repair",
                "urgency": "high" if "jaldi" in text.lower() or "kal" in text.lower() else "medium",
                "time_preference": "tomorrow morning",
                "location": "G-13",
                "budget_sensitivity": "high" if "zyada nahi" in text.lower() else "low",
                "is_emergency": "short circuit" in text.lower() or "burst" in text.lower() or "leak" in text.lower(),
                "confidence": 0.95
            }
        return {"confidence": 0.5} # Low confidence

    prompt = f"""
    You are the Intent Agent for KaamConnect, an autonomous service OS in Pakistan.
    Analyze the following user request which may be in Urdu, Roman Urdu, or English.
    
    Request: "{text}"
    
    Extract the following information and return ONLY a valid JSON object:
    - service_category: The normalized category (e.g., 'ac_repair', 'plumbing', 'electrician')
    - urgency: 'low', 'medium', or 'high'
    - time_preference: e.g., 'tomorrow morning', 'today evening', or 'asap'
    - location: The neighborhood or city mentioned (e.g., 'G-13', 'DHA Lahore')
    - budget_sensitivity: 'low', 'medium', or 'high'
    - is_emergency: boolean. True ONLY if words indicating severe danger or extreme damage are present (e.g., short circuit, aag, pipe burst, gas leak).
    - confidence: A float from 0.0 to 1.0 indicating how confident you are in this parsing.

    Format the output as strict JSON.
    """

    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
            )
        )
        return json.loads(response.text)
    except Exception as e:
        print(f"Gemini API Error: {e}")
        return {"confidence": 0.0, "error": str(e)}

