import requests
import json

payload = {
    "task_id": "task_automation_test_005",
    "goal": "Review nabmakeup.com for SEO, UX, and conversion issues",
    "context": { "url": "https://nabmakeup.com", "no_login": True },
    "limits": { "time_minutes": 10 }
}

try:
    r = requests.post("http://127.0.0.1:8008/plan", json=payload)
    print(f"Status: {r.status_code}")
    print(json.dumps(r.json(), indent=2))
except Exception as e:
    print(f"Error: {e}")
