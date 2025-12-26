import requests
import time
import sys

BASE_URL = "http://localhost:5000"

def check_backend():
    print(f"[*] Pinging Backend at {BASE_URL}...")
    try:
        # Check Beacon
        resp = requests.get(f"{BASE_URL}/api/health/beacon", timeout=5)
        if resp.status_code == 200:
            print("   [OK] Backend Beacon: OK")
        else:
            print(f"   [FAIL] Backend Beacon: Failed ({resp.status_code})")
            return False

        # Check DB Connectivity via Status
        resp = requests.get(f"{BASE_URL}/api/status", timeout=5)
        if resp.status_code == 200:
            data = resp.json()
            print(f"   [OK] Database Status: Connected (Missions: {data['stats'].get('missions_run', '?')})")
        else:
            print(f"   [FAIL] Database Status: Failed ({resp.text})")
            return False
            
        return True
    except Exception as e:
        print(f"   [FAIL] Connection Error: {e}")
        return False

if __name__ == "__main__":
    print("--- AUTOMATED SYSTEM VERIFICATION ---")
    attempts = 10
    success = False
    
    for i in range(attempts):
        if check_backend():
            success = True
            break
        print(f"   ... waiting for server boot ({i+1}/{attempts}) ...")
        time.sleep(3)
        
    if success:
        print("\n[SUCCESS] SYSTEM IS OPERATIONAL")
        sys.exit(0)
    else:
        print("\n[FAIL] SYSTEM STARTUP FAILED")
        sys.exit(1)
