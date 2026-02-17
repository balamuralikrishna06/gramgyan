import requests
import json

API_URL = "http://127.0.0.1:8000/api/v1/speech/speak"
OUTPUT_FILE = "tamil_test.wav"

payload = {
    "text": "வணக்கம், இது ஒரு சோதனை பதிவு.",  # "Hello, this is a test recording."
    "language_code": "ta-IN",
    "target_speaker_gender": "female"
}

try:
    print(f"Sending request to {API_URL}...")
    response = requests.post(API_URL, json=payload, stream=True)
    
    if response.status_code == 200:
        with open(OUTPUT_FILE, "wb") as f:
            for chunk in response.iter_content(chunk_size=1024):
                if chunk:
                    f.write(chunk)
        print(f"Success! Audio saved to: {OUTPUT_FILE}")
        print("You can now use this file to test the /transcribe endpoint.")
    else:
        print(f"Error: {response.status_code} - {response.text}")

except Exception as e:
    print(f"Exception: {e}")
