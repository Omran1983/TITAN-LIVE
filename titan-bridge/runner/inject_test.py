import os
import httpx
import time

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_SERVICE_ROLE_KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]

def sb_headers():
    return {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=representation",
    }

def inject():
    url = f"{SUPABASE_URL}/rest/v1/az_commands"
    payload = {
        "title": "Manual Injection Test",
        "intent": "shell.powershell",
        "objective": "Verify runner connectivity",
        "inputs": {"command": "Write-Host 'HELLO FROM INJECTOR!'"},
        "priority": 1,
        "state": "QUEUED"
    }
    
    print(f"Injecting command to {url}...")
    r = httpx.post(url, headers=sb_headers(), json=payload)
    print(f"Status: {r.status_code}")
    print(f"Response: {r.text}")

if __name__ == "__main__":
    inject()
