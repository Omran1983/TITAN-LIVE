
import os
import requests
import json

# Try to load env manually if not present
try:
    with open(".env", "r") as f:
        for line in f:
            if "GOOGLE_AI_KEY" in line or "GOOGLE_API_KEY" in line:
                key, val = line.strip().split("=", 1)
                os.environ[key] = val
except: pass

API_KEY = os.environ.get("GOOGLE_AI_KEY") or os.environ.get("GOOGLE_API_KEY")

if not API_KEY:
    print("ERROR: No API Key found.")
    exit(1)

print(f"Testing Gemini with Key: {API_KEY[:5]}...{API_KEY[-5:]}")

models = ["gemini-1.5-pro-latest", "gemini-1.5-flash", "gemini-pro"]

for model in models:
    print(f"\n--- Testing {model} ---")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={API_KEY}"
    payload = {
        "contents": [{
            "parts": [{"text": "Hello, are you online? Reply with JSON: {\"status\": \"online\"}"}]
        }]
    }
    
    try:
        resp = requests.post(url, json=payload, timeout=10)
        print(f"Status: {resp.status_code}")
        if resp.status_code == 200:
            print("Success!")
            print(resp.text[:200])
            break # Found a working one
        else:
            print(f"Fail: {resp.text}")
    except Exception as e:
        print(f"Exception: {e}")
