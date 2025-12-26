import os
import sys
import argparse
import json
import time
from supabase import create_client, Client

# Initialize Supabase
url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

if not url or not key:
    print(json.dumps({"action": "error", "error": "Missing SUPABASE_URL or KEY"}))
    sys.exit(1)

supabase: Client = create_client(url, key)

def log_incident(component, error_msg):
    """Log the incident to DB and return ID."""
    data = {
        "component": component,
        "error_signature": error_msg[:200], # Trucate
        "status": "investigating",
        "severity": "medium"
    }
    try:
        resp = supabase.table("az_reflex_incidents").insert(data).execute()
        return resp.data[0]['id']
    except Exception as e:
        # Fallback if DB is down
        return None

def find_rule(error_msg):
    """Scan rules table for regex/keyword matches in the error message."""
    try:
        # Fetch all rules (caching strategy would be better for prod)
        resp = supabase.table("az_reflex_rules").select("*").order("priority", desc=True).execute()
        rules = resp.data
        
        for rule in rules:
            pattern = rule['error_pattern']
            if pattern.lower() in error_msg.lower():
                return rule
    except Exception:
        pass
    return None

def diagnose(component, error_msg, log_tail):
    # 1. Log Incident
    incident_id = log_incident(component, error_msg)
    
    # 2. Check Rules (Heuristics)
    rule = find_rule(error_msg + "\n" + log_tail)
    
    if rule:
        action_plan = rule['action_plan']
        reason = f"Matched rule: {rule['error_pattern']}"
    else:
        # 3. Default / Fallback
        
        # L5 UPGRADE: Check for Code Errors (Syntax, Type, Attribute)
        # If it looks like a code crash, prescribing a "Patch" via CodeAgent.
        code_crash_markers = ["SyntaxError", "AttributeError", "TypeError", "NameError", "IndentationError"]
        if any(m in error_msg for m in code_crash_markers) or any(m in log_tail for m in code_crash_markers):
             action_plan = {
                 "action": "patch", 
                 "instruction": f"Fix the following python error in component '{component}': {error_msg} \nLogs: {log_tail[:500]}",
                 "target_component": component
             }
             reason = "Heuristic: Identified Code Crash. Prescribing Auto-Patch."
        else:
            action_plan = {"action": "escalate", "message": "No heuristic match. Human review needed."}
            reason = "No matching rules found."

    # 4. Log Action
    if incident_id:
        supabase.table("az_reflex_actions").insert({
            "incident_id": incident_id,
            "action_type": action_plan.get("action", "unknown"),
            "details": action_plan,
            "result": "pending"
        }).execute()
        
    return {
        "incident_id": incident_id,
        "action": action_plan.get("action"),
        "params": action_plan,
        "reason": reason
    }

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--component", required=True)
    parser.add_argument("--error", default="Unknown Error")
    parser.add_argument("--logs", default="")
    args = parser.parse_args()

    decision = diagnose(args.component, args.error, args.logs)
    print(json.dumps(decision))
