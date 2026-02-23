import asyncio
import httpx
import os
from dotenv import load_dotenv

load_dotenv()
API_KEY = os.getenv("SARVAM_API_KEY")

async def test_transliterate():
    tanglish = "Enathu chedi Roja chedi irukirathu"
    payload = {
        "input": tanglish,
        "source_language_code": "en-IN",
        "target_language_code": "ta-IN",
        "speaker_gender": "Male",
        "mode": "classic-colloquial",
        "numerals_format": "international",
        "output_script": "fully-native",
    }
    headers = {"api-subscription-key": API_KEY, "Content-Type": "application/json"}
    async with httpx.AsyncClient(timeout=30) as client:
        r = await client.post("https://api.sarvam.ai/transliterate", json=payload, headers=headers)
        data = r.json()
        print("Keys:", list(data.keys()))
        for k, v in data.items():
            print(f"  {k}: {v}")

if __name__ == "__main__":
    asyncio.run(test_transliterate())
