
import requests
import json
import time

BASE_URL = "http://localhost:5000/api"
HEADERS_ADMIN = {"X-Citadel-Token": "12345-abcde"} # Matches .env usually? We need to know the token.
# wait, .env CITADEL_TOKEN is needed. Let's assume we can get it or fail.
import os
from dotenv import load_dotenv
load_dotenv()
TOKEN = os.environ.get("CITADEL_TOKEN")
HEADERS = {"X-Citadel-Token": TOKEN}

def test_governance():
    print("EXT-GOV V2 Verifier Started...")
    
    # 1. Health Check
    try:
        r = requests.get(f"{BASE_URL}/status")
        if r.status_code != 200:
            print(f"Server Fail: {r.status_code} - {r.text}")
            return
        print("Server Online")
    except:
        print("Connect Fail")
        return

    # 2. Authority Check (Anonymous)
    print("\n--- Test 1: Authority (Anonymous) ---")
    r = requests.post(f"{BASE_URL}/tools/action", json={"tool": "titan", "action": "restart"})
    print(f"Status: {r.status_code} (Expected 403)")
    if r.status_code == 403 and "Authority Denied" in r.text:
        print("PASS: Anonymous blocked")
    else:
        print(f"FAIL: {r.text}")

    # 3. Intent Check (Missing Intent)
    print("\n--- Test 2: Intent Requirement ---")
    # titan:restart requires intent
    r = requests.post(f"{BASE_URL}/tools/action", json={"tool": "titan", "action": "restart"}, headers=HEADERS)
    print(f"Status: {r.status_code} (Expected 403)")
    if r.status_code == 403 and "Missing Intent ID" in r.text:
         print("PASS: Missing Intent blocked")
    else:
         print(f"FAIL: {r.text}")

    # 4. Success Path (Valid Intent + Token)
    print("\n--- Test 3: Valid Execution ---")
    # Use ollama:pull which allows L1 (User) but we are Admin (L4) so ok.
    # Note: titan:restart needs L3. Admin is L4.
    payload = {
        "tool": "ollama", 
        "action": "pull", 
        "payload": {"model": "tinyllama"},
        "intent_id": "test-intent-uuid-123" 
    }
    r = requests.post(f"{BASE_URL}/tools/action", json=payload, headers=HEADERS)
    print(f"Status: {r.status_code}")
    print(f"Response: {r.text}")
    
    if r.status_code == 200:
        print("PASS: Execution Allowed")
    else:
        print("FAIL: Execution Blocked")

    # 5. Audit Log V2 Verification
    print("\n--- Test 4: Audit Log V2 Inspection ---")
    # We need to query DB.
    import psycopg2
    from psycopg2.extras import RealDictCursor
    conn = psycopg2.connect(os.environ.get("JARVIS_DB_CONN"))
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    cur.execute("SELECT * FROM az_audit_log ORDER BY ts DESC LIMIT 1")
    row = cur.fetchone()
    
    print("Latest Log Entry:")
    print(f"Action: {row['action']}")
    print(f"Role: {row.get('actor_role')}")
    print(f"Result: {row.get('result')}")
    print(f"Exec Meta: {row.get('exec_meta')}")
    
    if row['result'] == 'SUCCESS' and row.get('exec_meta'):
        print("PASS: V2 Audit Fields Present")
    else:
        print("FAIL: Audit Data Missing")

if __name__ == "__main__":
    test_governance()
