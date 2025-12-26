
import requests
import os
from dotenv import load_dotenv

load_dotenv(r"f:\AION-ZERO\.env")
api_key = os.environ.get("JARVIS_COMMANDS_API_KEY", "jarvis-secret")

url = "http://localhost:8001/api/status"
headers = {"X-API-KEY": api_key}

try:
    print(f"CONNECTING TO: {url}")
    resp = requests.get(url, headers=headers)
    print(f"STATUS: {resp.status_code}")
    print(f"CONTENT: {resp.text}")
except Exception as e:
    print(f"ERROR: {e}")
