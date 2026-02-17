import requests
import os
import sys

# Force UTF-8 encoding for stdout
sys.stdout.reconfigure(encoding='utf-8')

API_URL = "http://127.0.0.1:8000/api/v1/speech/process"
AUDIO_FILE = "tamil_test.wav" # Ensure this file exists or generate it

def test_process_workflow():
    if not os.path.exists(AUDIO_FILE):
        print(f"Error: {AUDIO_FILE} not found. Run generate_test_audio.py first.")
        return

    print(f"Uploading {AUDIO_FILE} to {API_URL}...")
    
    with open(AUDIO_FILE, "rb") as f:
        files = {"file": (AUDIO_FILE, f, "audio/wav")}
        data = {
            "source_language": "ta-IN",
            "target_language": "en-IN"
        }
        
        try:
            response = requests.post(API_URL, files=files, data=data)
            
            if response.status_code == 200:
                result = response.json()
                print("\n--- Success! ---")
                print(f"Transcript (Tamil): {result.get('transcript')}")
                print(f"Translation (English): {result.get('translation')}")
                print("----------------")
            else:
                print(f"Error: {response.status_code} - {response.text}")
        except Exception as e:
            print(f"Exception: {e}")

if __name__ == "__main__":
    test_process_workflow()
