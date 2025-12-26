import requests
import json

URL = "http://localhost:5000/api/library"

try:
    print(f"Testing {URL}...")
    res = requests.get(URL, timeout=5)
    if res.status_code == 200:
        data = res.json()
        if data.get('ok') and len(data.get('items', [])) > 0:
            print(f"SUCCESS: Found {len(data['items'])} items.")
            print(f"Sample: {data['items'][0][1]}") # First item name
            exit(0)
        else:
            print("FAIL: Response ok but no items?")
            print(data)
            exit(1)
    else:
        print(f"FAIL: HTTP {res.status_code}")
        print(res.text)
        exit(1)
except Exception as e:
    print(f"FAIL: {e}")
    exit(1)
