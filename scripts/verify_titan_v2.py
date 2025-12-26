import requests
import json
import time

BASE_URL = "http://127.0.0.1:5000"
TOKEN = "OPERATOR"

def heading(text):
    print(f"\n{'='*50}\n{text}\n{'='*50}")

def test(name, func):
    print(f"\n>>> TEST: {name}")
    try:
        func()
        print("✅ PASS")
    except Exception as e:
        print(f"❌ FAIL: {e}")

def get(path):
    r = requests.get(f"{BASE_URL}{path}", headers={"Authorization": f"Bearer {TOKEN}"})
    if r.status_code >= 400:
        raise Exception(f"Status {r.status_code}: {r.text}")
    print(f"   Response: {json.dumps(r.json(), indent=2)[:300]}...")
    return r.json()

def post(path, body):
    r = requests.post(f"{BASE_URL}{path}", json=body, headers={"Authorization": f"Bearer {TOKEN}"})
    if r.status_code >= 400:
        raise Exception(f"Status {r.status_code}: {r.text}")
    print(f"   Response: {json.dumps(r.json(), indent=2)[:300]}...")
    return r.json()

def run_tests():
    heading("TITAN 5-CYCLE SYSTEM CHECK")

    test("1. Health Check", lambda: get("/api/health"))

    def check_capabilities():
        caps = get("/api/capabilities")
        if not caps.get("ok"): raise Exception("Capabilities failed")
    test("2. Capabilities Registry", check_capabilities)

    def run_agent():
        print("   Running WebsiteReviewAgent on https://example.com ...")
        res = post("/api/agents/website-review", {"url": "https://example.com"})
        if not res.get("ok"): raise Exception("Agent failed")
        if not res.get("review"): raise Exception("Missing review in output")
    test("3. Agent: Website Review (Scrape->Store->Index)", run_agent)

    def check_audit():
        logs = get("/api/audit?limit=5")
        if not logs.get("items") or len(logs["items"]) == 0:
            raise Exception("Audit log empty (expected entries after agent run)")
    test("4. Audit Log Verification", check_audit)

    def create_intent():
        print("   Creating L2 Intent (restart_n8n)...")
        res = post("/api/governance/intent", {
            "proposed_action": "titan:restart_n8n",
            "risk_level": "L4",
            "explanation": "Test intent"
        })
        if not res.get("intent_id"): raise Exception("No intent_id returned")
        return res["intent_id"]
    
    intent_id = []
    test("5. Governance: Create Intent", lambda: intent_id.append(create_intent()))

    def approve_intent():
        if not intent_id: return 
        print(f"   Approving Intent {intent_id[0]}...")
        # L3 required
        r = requests.post(f"{BASE_URL}/api/governance/intent/{intent_id[0]}/approve", 
                         headers={"Authorization": "Bearer ADMIN"})
        if r.status_code != 200: raise Exception(f"Approval failed: {r.text}")
    test("6. Governance: Approve Intent", approve_intent)

    print("\nALL SYSTEM TESTS COMPLETED.")

if __name__ == "__main__":
    run_tests()
