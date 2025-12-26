import os
import requests
import sys
from dotenv import load_dotenv

load_dotenv(r"f:\AION-ZERO\.env")

def verify():
    print("=== VERIFYING FIXES ===")
    
    # 1. Check Global_AI_Search
    if os.path.exists(r"f:\AION-ZERO\scripts\Global_AI_Search.ps1"):
        print("[FIXED] Global_AI_Search.ps1 exists.")
    else:
        print("[FAIL] Global_AI_Search.ps1 missing.")
        
    # 2. Check GitHub Auth (Real Repo Access)
    try:
        sys.path.append(r"f:\AION-ZERO")
        from citadel.integrations.github_app_auth import get_github_token
        token = get_github_token()
        print(f"ℹ️  Token generated: {token[:4]}...{token[-4:]}")
        
        headers = {"Authorization": f"Bearer {token}", "Accept": "application/vnd.github.v3+json"}
        url = "https://api.github.com/repos/Omran1983/AION-ZERO"
        
        r = requests.get(url, headers=headers)
        if r.status_code == 200:
            print(f"[FIXED] GitHub Auth Active. Access granted to {r.json().get('full_name')}")
        else:
            print(f"[FAIL] GitHub Auth Error {r.status_code}: {r.text}")
            print("   -> ACTION: Install the AION-ZERO GitHub App on the 'Omran1983' account.")
            
    except Exception as e:
        print(f"[FAIL] GitHub Check Exception: {e}")

if __name__ == "__main__":
    verify()
