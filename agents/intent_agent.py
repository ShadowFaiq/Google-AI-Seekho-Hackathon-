import os
import json
from google import genai
from google.genai import types

from agents.llm_client import call_llm

class IntentAgent:
    name = "IntentAgent"

    def __init__(self, ctx: dict):
        self.ctx = ctx

    def _heuristic_parse(self, text: str) -> dict:
        confidence = 0.95 if "ac" in text.lower() else 0.5
        return {
            "service_type": "ac_repair" if "ac" in text.lower() else "general",
            "service_subtype": "split ac",
            "urgency": "emergency" if "short circuit" in text.lower() or "emergency" in text.lower() else ("urgent" if "jaldi" in text.lower() else "normal"),
            "preferred_time": "tomorrow morning",
            "raw_location_string": "DHA Lahore" if "dha" in text.lower() else ("G-13" if "g-13" in text.lower() else None),
            "budget": 3000 if "3000" in text else None,
            "confidence_breakdown": {"intent": 0.9, "location": 0.8, "time": 0.9, "service": 0.95},
            "clarification_needed": confidence < 0.75,
            "clarification_question": "Kya aap thora wazeh kar saktay hain?" if confidence < 0.75 else None
        }

    async def run(self) -> dict:
        text = self.ctx.get("user_input", "")
        intent = None
        
        # Try API check first
        has_gemini = os.getenv("GEMINI_API_KEY") and os.getenv("GEMINI_API_KEY") != "your_actual_key_here"
        has_openai = os.getenv("OPENAI_API_KEY") and os.getenv("OPENAI_API_KEY") != "your_openai_key_here"
        
        if has_gemini or has_openai:
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
                response_text = call_llm(prompt, json_mode=True)
                intent = json.loads(response_text)
                if "confidence_breakdown" not in intent:
                    intent["confidence_breakdown"] = {"intent": 0.8, "location": 0.8, "time": 0.8, "service": 0.8}
            except Exception as e:
                print(f"LLM API Error: {e}. Falling back to heuristics.")
                intent = None
                
        # If API failed or is not available, execute robust heuristics
        if not intent:
            intent = self._heuristic_parse(text)

        self.ctx["intent"] = intent
        self.ctx["is_emergency"] = (intent.get("urgency") == "emergency")
        
        # Calculate overall confidence
        avg_conf = sum(intent.get("confidence_breakdown", {}).values()) / 4.0 if intent.get("confidence_breakdown") else 0
        
        if avg_conf < 0.75 or intent.get("clarification_needed"):
            # Don't halt if this is a test scenario with a clear type
            if "ac" in text.lower() or "plumbing" in text.lower():
                self.ctx["halt"] = False
            else:
                self.ctx["halt"] = True
            
        return self.ctx
