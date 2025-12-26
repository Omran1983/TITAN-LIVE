import requests
import json

URL = "http://localhost:5000/api/library"

# Test cases
cases = [
    {"q": "", "cat": "all", "expect_some": True},
    {"q": "", "cat": "ai", "expect_some": True}, # Should have OpenAI stuff
    {"q": "postgres", "cat": "all", "expect_some": True},
]

for c in cases:
    full_url = f"{URL}?q={c['q']}&cat={c['cat']}"
    print(f"Testing {full_url}...")
    try:
        res = requests.get(full_url, timeout=5)
        if res.status_code == 200:
            data = res.json()
            count = len(data.get('items', []))
            print(f"   -> Count: {count}")
            if c['expect_some'] and count == 0:
                print("   [FAIL] Expected items but got none.")
            else:
                print("   [OK]")
        else:
            print(f"   [FAIL] HTTP {res.status_code}")
    except Exception as e:
        print(f"   [FAIL] {e}")
