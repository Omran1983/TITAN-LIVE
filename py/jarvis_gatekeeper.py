"""
THE GATEKEEPER (PHASE 18)
-------------------------
Safety Filter for Self-Improvement.
Enforces the "Immutable Zone".
"""

import json
import os

IMMUTABLE_FILES = [
    "Panic-Stop.ps1",
    ".env",
    "Jarvis-LoadEnv.ps1",
    "fingerprint.py",
    "jarvis_gatekeeper.py" # Self-Protection
]

PLAN_FILE = r"F:\AION-ZERO\reports\architect_plan.json"

def audit_plan():
    if not os.path.exists(PLAN_FILE):
        print("[GATEKEEPER] No plan to audit.")
        return

    with open(PLAN_FILE, "r") as f:
        plan = json.load(f)

    instruction = plan.get("instruction", "").lower()
    
    # 1. Check Immutable Zone
    for forbidden in IMMUTABLE_FILES:
        if forbidden.lower() in instruction:
            print(f"[GATEKEEPER] 🛑 BLOCKED: Plan attempts to modify immutable file: {forbidden}")
            return

    # 2. Check Risk (If Architect flagged it as high)
    if plan.get("risk", "low") == "high":
         print("[GATEKEEPER] ⚠️ FLAGGED: High Risk plan requires Human Approval.")
         return

    print(f"[GATEKEEPER] ✅ APPROVED: {plan['title']}")
    print(" -> Authorization Token Issued for CodeAgent.")
    # In a full loop, this would post the command to Supabase with status='queued'

if __name__ == "__main__":
    audit_plan()
