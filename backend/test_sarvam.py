import os
import httpx
import wave
import asyncio
from dotenv import load_dotenv

# Load env vars
load_dotenv()

API_KEY = os.getenv("SARVAM_API_KEY")
SARVAM_STT_URL = "https://api.sarvam.ai/speech-to-text"

def create_dummy_wav(filename="test.wav"):
    with wave.open(filename, 'wb') as wav_file:
        # Set parameters: 1 channel, 2 bytes per sample, 16000 sample rate, 16000 frames (1 sec)
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(16000)
        # Write 1 second of silence
        wav_file.writeframes(b'\x00' * 32000)
    return filename

async def test_stt():
    filename = create_dummy_wav()
    print(f"Created dummy file: {filename}")
    
    if not API_KEY:
        print("Error: SARVAM_API_KEY not found in .env")
        return

    headers = {"api-subscription-key": API_KEY}
    data = {"model": "saarika:v2", "language_code": "ta-IN"}
    
    print(f"Testing Sarvam STT with URL: {SARVAM_STT_URL}")
    print(f"Headers: {headers.keys()}") # Don't print full key
    print(f"Data: {data}")

    async with httpx.AsyncClient() as client:
        with open(filename, "rb") as f:
            files = {"file": (filename, f, "audio/wav")}
            try:
                response = await client.post(SARVAM_STT_URL, headers=headers, files=files, data=data)
                print(f"Status Code: {response.status_code}")
                print(f"Response Body: {response.text}")
                response.raise_for_status()
                print("Success!")
            except Exception as e:
                print(f"Exception: {e}")

    # Cleanup
    if os.path.exists(filename):
        os.remove(filename)

if __name__ == "__main__":
    asyncio.run(test_stt())
