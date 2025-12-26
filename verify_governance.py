
import requests
import psycopg2
import os
import json
import time
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

load_dotenv()
DB_URL = os.environ.get("JARVIS_DB_CONN")

def verify():
    print("EXT-GOV Check Initiated...")
    
    # 1. Health Check
    try:
        r = requests.get("http://localhost:5000/api/status")
        if r.status_code == 200:
            print("Titan Server (Governor) is ONLINE.")
        else:
            print(f"Titan Server is failing health check: {r.status_code}")
            return
    except Exception as e:
        print(f"Connection Failed: {e}")
        return

    # 2. Trigger Action (Ollama Pull)
    print("Triggering Governed Action: ollama:pull...")
    payload = {
        "tool": "ollama",
        "action": "pull",
        "payload": {"model": "tinyllama"}
    }
    headers = {"X-Citadel-Token": "test-token"} # Simulated token
    
    try:
        r = requests.post("http://localhost:5000/api/tools/action", json=payload, headers=headers)
        print(f"   Response: {r.status_code} {r.text}")
    except Exception as e:
        print(f"   Action trigger failed: {e}")

    # 3. Verify Audit Log
    print("Auditing Ledger...")
    conn = psycopg2.connect(DB_URL, cursor_factory=RealDictCursor)
    cur = conn.cursor()
    
    cur.execute("SELECT * FROM az_audit_log ORDER BY id DESC LIMIT 1")
    row = cur.fetchone()
    
    if row:
        print(f"   Latest Entry: ID={row['id']} ACTION={row['action']} RISK={row['risk_level']} STATUS={row['status']}")
        if row['action'] == 'ollama:pull' and row['risk_level'] == 'L2':
            print("GOVERNANCE VERIFIED: Action was governed and audited correctly.")
        else:
            print("GOVERNANCE MISMATCH: Log entry does not match expected values.")
    else:
        print("NO AUDIT LOG FOUND.")
        
    cur.close()
    conn.close()

if __name__ == "__main__":
    verify()
