
import requests
import sys
import os

# CONFIG
BASE_URL = "https://www.titansubmit.com"
CRON_SECRET = os.environ.get("CRON_SECRET", "mock_secret") # Use mock if local

def check(name, url, method="GET", headers=None, expected_status=200):
    try:
        print(f"Checking {name}...", end=" ")
        if method == "GET":
            res = requests.get(url, headers=headers)
        
        if res.status_code == expected_status:
            print("✅ PASS")
            return True
        else:
            print(f"❌ FAIL ({res.status_code})")
            return False
    except Exception as e:
        print(f"❌ ERROR: {e}")
        return False

def verify_jarvis():
    print("Checking Jarvis Patrol...", end=" ")
    # This might fail on prod without real secret, but we check if endpoint exists
    # We expect 200 or 403 (if secret protected). 
    # Since we are testing from outside, we likely get 200 if secret is not enforced strictly in code yet (we added WARN mode).
    try:
        res = requests.get(f"{BASE_URL}/api/jarvis/patrol", headers={"Authorization": f"Bearer {CRON_SECRET}"})
        data = res.json()
        if data.get("action") == "PATROL":
             print("✅ PASS (Logic Active)")
        else:
             print("⚠️ WARN (Unexpected Response)")
    except Exception as e:
        print(f"❌ ERROR: {e}")

print("--- TITAN PHASE 2 VERIFICATION ---\n")
check("Login Page", f"{BASE_URL}/portal/login")
check("Vault UI", f"{BASE_URL}/portal/vault")
check("Feature Forge", f"{BASE_URL}/portal/forge")
verify_jarvis()
print("\n--- END ---")
