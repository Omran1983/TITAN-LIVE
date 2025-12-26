"""
THE ARCHITECT (PHASE 18)
------------------------
Reads Self-Audit Reports.
Plans Engineering Taks.
"""

import os
import json
import glob
from jarvis_brain_local import JarvisBrain
# Note: In a full implementation, we would reuse database logic from jarvis_revenue_gen.py
# For now, we print the plan for the Gatekeeper to approve.

REPORT_DIR = r"F:\AION-ZERO\reports\self_audit"

def get_latest_report():
    files = glob.glob(f"{REPORT_DIR}\\*.json")
    if not files:
        return None
    return max(files, key=os.path.getctime)

def plan_improvements():
    report_file = get_latest_report()
    if not report_file:
        print("[ARCHITECT] No audit report found.")
        return

    print(f"[ARCHITECT] Analyzing Report: {report_file}")
    with open(report_file, "r") as f:
        audit_data = json.load(f)

    if not audit_data.get("detected_inefficiencies"):
        print("[ARCHITECT] System is Green. No improvements needed.")
        return

    # Use Brain to Plan
    brain = JarvisBrain()
    issues_str = json.dumps(audit_data["detected_inefficiencies"])
    
    prompt = f"""
    You are the Chief Software Architect of AION-ZERO.
    Analyze these detected system issues:
    {issues_str}
    
    Propose 1 concrete, low-risk engineering task to fix the most critical issue.
    Format your response as a valid JSON object:
    {{
        "title": "Refactor Watchdog Loop",
        "instruction": "Update scripts/Jarvis-Watchdog.ps1 to increase sleep interval to 60s.",
        "risk": "low"
    }}
    """
    
    print("[ARCHITECT] Consulting Brain...")
    brain.history = [{"role": "user", "content": prompt}]
    plan_json = brain.think()
    
    if plan_json and "{" in plan_json:
        try:
            # Extract JSON if brain wrapped it in text
            if "```json" in plan_json:
                 plan_json = plan_json.split("```json")[1].split("```")[0].strip()
            
            plan = json.loads(plan_json)
            
            print(f"\n[ARCHITECT] Proposed Plan: {plan['title']}")
            print(f"Risk: {plan.get('risk')}")
            print(f"Instruction: {plan['instruction']}")
            
            # In Phase 18.3, we would send this to the Gatekeeper.
            # For now, we save it as a 'Draft Proposal'.
            with open(r"F:\AION-ZERO\reports\architect_plan.json", "w") as f:
                json.dump(plan, f, indent=2)
                
        except Exception as e:
            print(f"[ARCHITECT] Brain returned bad JSON: {e}")
            print(plan_json)
    else:
        print("[ARCHITECT] Brain failed to plan.")

if __name__ == "__main__":
    plan_improvements()
