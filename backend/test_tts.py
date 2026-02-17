import os
import httpx
import asyncio
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("SARVAM_API_KEY")
SARVAM_TTS_URL = "https://api.sarvam.ai/text-to-speech"

import sys

# Force UTF-8 encoding for stdout
sys.stdout.reconfigure(encoding='utf-8')

async def test_tts():
    if not API_KEY:
        print("Error: SARVAM_API_KEY not found in .env")
        return

    headers = {
        "api-subscription-key": API_KEY,
        "Content-Type": "application/json"
    }
    
    # Try with v1 first (to confirm error)
    payload = {
        "inputs": ["Hello"], # Use English to avoid console encoding issues for now
        "target_language_code": "ta-IN",
        "speaker": "kavitha",
        "pitch": 0,
        "pace": 1.0,
        "loudness": 1.5,
        "speech_sample_rate": 16000,
        "enable_preprocessing": True,
        "model": "bulbul:v3"
    }

    print(f"Testing Sarvam TTS with URL: {SARVAM_TTS_URL}")
    # print(f"Payload: {payload}") # formatted print might fail

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(SARVAM_TTS_URL, headers=headers, json=payload)
            print(f"Status Code: {response.status_code}")
            print(f"Response Body: {response.text}")
        except Exception as e:
            print(f"Exception: {e}")

if __name__ == "__main__":
    asyncio.run(test_tts())
