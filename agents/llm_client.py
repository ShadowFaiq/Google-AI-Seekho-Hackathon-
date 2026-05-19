import os
import json
from openai import OpenAI

# Initialize client safely
openai_client = None

try:
    openai_key = os.getenv("OPENAI_API_KEY")
    if openai_key and openai_key != "your_openai_key_here":
        openai_client = OpenAI(api_key=openai_key)
except Exception as e:
    print(f"Warning: Could not initialize OpenAI Client: {e}")

def call_llm(prompt: str, json_mode: bool = False) -> str:
    """
    Calls the OpenAI provider and returns the text response.
    """
    global openai_client
    if not openai_client:
        # Try re-initializing dynamically in case env was loaded late
        try:
            openai_key = os.getenv("OPENAI_API_KEY")
            if openai_key and openai_key != "your_openai_key_here":
                openai_client = OpenAI(api_key=openai_key)
        except Exception:
            pass

    if openai_client:
        try:
            response_format = {"type": "json_object"} if json_mode else None
            response = openai_client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": "You are a helpful assistant for KaamConnect (autonomous Pakistani service OS)."},
                    {"role": "user", "content": prompt}
                ],
                response_format=response_format,
                temperature=0.2
            )
            return response.choices[0].message.content
        except Exception as e:
            print(f"OpenAI API Error: {e}.")
            raise e
            
    raise RuntimeError("No OpenAI client is configured or available! Please set OPENAI_API_KEY in your .env file.")
