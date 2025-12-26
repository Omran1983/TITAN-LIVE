
import requests
import json
import sys
import time

BASE_URL = "http://localhost:5000"
TOKEN = "demo-token" # L0
ADMIN_TOKEN = "citadel-key-x7y8z9" # L4 (from env)

def test_endpoint(name, url, headers=None, expected_status=200):
    print(f"--- Testing {name} ---")
    try:
        r = requests.get(url, headers=headers, timeout=2)
        print(f"Status: {r.status_code}")
        try:
            print(f"Response: {json.dumps(r.json(), indent=2)}")
        except:
            print(f"Response: {r.text[:200]}")
        
        if r.status_code == expected_status:
            print("PASS")
            return True, r.json() if r.headers.get('content-type') == 'application/json' else r.text
        else:
            print(f"FAIL (Expected {expected_status})")
            return False, None
    except Exception as e:
        print(f"FAIL (Connection Error: {e})")
        return False, None

def check_governance_proof():
    print("\n--- Governance Proof Tests ---")
    
    # 1. High Risk / No Token
    print("1. High Risk Action (No Token) -> Expect 403")
    r1 = requests.post(f"{BASE_URL}/api/tools/action", json={"tool": "titan", "action": "restart"})
    print(f"Result: {r1.status_code} (Expected 403)")
    
    # 2. High Risk / Token / No Intent
    print("2. High Risk Action (With Token, No Intent) -> Expect 403 (Governance Blocked)")
    headers = {"X-Citadel-Token": TOKEN}
    r2 = requests.post(f"{BASE_URL}/api/tools/action", json={"tool": "titan", "action": "restart"}, headers=headers)
    print(f"Result: {r2.status_code}")
    print(f"Payload: {r2.text}")
    
    # 3. Valid Low Risk / Token
    print("3. Low Risk Action (With Token) -> Expect 200")
    r3 = requests.post(f"{BASE_URL}/api/tools/action", json={"tool": "ollama", "action": "pull", "model": "tinyllama"}, headers=headers)
    print(f"Result: {r3.status_code}")

print("\n STARTING SYSTEM VERIFICATION ")
time.sleep(2) # Give server a moment after restart

# 1. Check Governance Status
ok_gov, gov_data = test_endpoint("Governance Status", f"{BASE_URL}/api/governance/status")

# 2. Check Agents Status
ok_agents, agent_data = test_endpoint("Agents Status", f"{BASE_URL}/api/health/agents")

# 3. Run Proofs
check_governance_proof()

print("\n VERIFICATION COMPLETE ")
