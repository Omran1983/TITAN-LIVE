import requests

url = "https://nabmakeup.com/"
headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36"}

try:
    resp = requests.get(url, headers=headers, timeout=15)
    print(f"Status: {resp.status_code}")
    print(f"Content Start: {resp.text[:500]}")
except Exception as e:
    print(f"Error: {e}")
