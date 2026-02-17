import os
import httpx
import asyncio
from dotenv import load_dotenv
import sys

# Force UTF-8 encoding for stdout
sys.stdout.reconfigure(encoding='utf-8')

load_dotenv()

API_KEY = os.getenv("SARVAM_API_KEY")
SARVAM_TRANSLATE_URL = "https://api.sarvam.ai/translate"

async def test_translation():
    if not API_KEY:
        print("Error: SARVAM_API_KEY not found in .env")
        return

    headers = {
        "api-subscription-key": API_KEY,
        "Content-Type": "application/json"
    }

    # Test payload
    payload = {
        "input": "வணக்கம், எப்படி இருக்கிறீர்கள்?", # "Hello, how are you?"
        "source_language_code": "ta-IN",
        "target_language_code": "en-IN",
        "speaker_gender": "Female",
        "mode": "formal",
        "model": "mayura:v1"
    }

    print(f"Testing Sarvam Translation with URL: {SARVAM_TRANSLATE_URL}")
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(SARVAM_TRANSLATE_URL, headers=headers, json=payload)
            print(f"Status Code: {response.status_code}")
            print(f"Response Body: {response.text}")
        except Exception as e:
            print(f"Exception: {e}")

if __name__ == "__main__":
    asyncio.run(test_translation())
