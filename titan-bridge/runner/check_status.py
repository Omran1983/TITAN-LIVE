import os
import httpx
import time
import json

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_SERVICE_ROLE_KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]

def sb_headers():
    return {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=representation",
    }

def check_latest():
    url = f"{SUPABASE_URL}/rest/v1/az_commands?select=*&limit=1&order=created_at.desc"
    
    print(f"Checking latest command from {url}...")
    r = httpx.get(url, headers=sb_headers())
    if r.status_code == 200:
        data = r.json()
        if data:
            print(json.dumps(data[0], indent=2))
        else:
            print("No commands found.")
    else:
        print(f"Error: {r.status_code} {r.text}")

if __name__ == "__main__":
    check_latest()
