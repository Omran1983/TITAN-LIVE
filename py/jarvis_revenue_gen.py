"""
JARVIS REVENUE GENERATOR (PYTHON PORT)
--------------------------------------
Phase 17: Python Migration
Roles:
1. Define Recurring Missions.
2. Brainstorm New Ideas (using jarvis_brain_local).
3. Queue Commands in Supabase.
"""

import os
import json
import time
import requests
from datetime import datetime, timedelta
import urllib.parse
from jarvis_brain_local import JarvisBrain # Direct Brain Integration

# --- CONFIG ---
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
PROJECT = "reachx"

HEADERS = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Prefer": "return=representation",
    "Content-Type": "application/json"
}

def log(msg):
    print(f"[RevenueGen] {msg}")

def get_queued_commands():
    # Helper to check recent commands
    pass 

def queue_command(instruction, origin="autonomous_revenue_gen"):
    url = f"{SUPABASE_URL}/rest/v1/az_commands"
    payload = {
        "project": PROJECT,
        "instruction": instruction,
        "status": "queued",
        "action": "code",
        "origin": origin
    }
    try:
        r = requests.post(url, headers=HEADERS, json=payload)
        r.raise_for_status()
        log(f" -> SUCCESS: Command Queued: {instruction[:50]}...")
    except Exception as e:
        log(f" -> ERROR: Failed to queue: {e}")

def check_duplicate(instruction, hours=24):
    """Checks if a similar instruction was queued recently."""
    since = (datetime.utcnow() - timedelta(hours=hours)).isoformat()
    # Simple exact match check for now
    encoded_inst = urllib.parse.quote(instruction)
    url = f"{SUPABASE_URL}/rest/v1/az_commands?select=id&project=eq.{PROJECT}&instruction=eq.{encoded_inst}&created_at=gt.{since}"
    
    try:
        r = requests.get(url, headers=HEADERS)
        data = r.json()
        if len(data) > 0:
            return True, data[0]['id']
        return False, None
    except:
        return False, None

def brainstorm_idea():
    """Uses the Brain to invent a task."""
    log("Consulting the Brain for new ideas...")
    brain = JarvisBrain()
    
    # We ask the brain directly. 
    # Since JarvisBrain.run_mission is a loop, we can just use its think() method or simple prompt if we exposed it.
    # But for now, let's reuse the think logic via a direct prompt if available, 
    # or just use the high-level run_mission to 'output' the idea.
    
    # Fast Path: Just call the brain's LLM directly
    prompt = f"Goal: Analyze '{PROJECT}' and propose one high-value coding task to improve user retention or revenue. Return ONLY the task instruction string."
    
    # We'll use the brain's internal method if possible, or just instantiate a new chat session
    # For simplicity in this port, let's just use the brain's call_ollama wrapper
    brain.history = [{"role": "user", "content": prompt}]
    idea = brain.think() # Uses the Hybrid Logic (Local -> Cloud)
    
    if idea and "{" not in idea: # Ensure it's text, not JSON tool call
        return idea.strip()
    return None

def main():
    log("=== REVENUE GENERATOR (PYTHON) ===")
    
    missions = [
        {
            "name": "Daily Insights Report", 
            "instruction": "Analyze the latest JSON backups in F:\\AION-ZERO\\backups and generate a markdown report 'daily_insights.md' summarizing new candidates, jobs, and matches.",
            "freq": 24
        },
        {
            "name": "UX Optimization Check",
            "instruction": "Review the codebase for 'reachx' (if available) or generic UI components and propose 1 optimization for speed or conversion.",
            "freq": 48
        }
    ]
    
    # 1. Standard Missions
    for m in missions:
        log(f"Checking Mission: {m['name']}...")
        is_dup, _ = check_duplicate(m['instruction'], m['freq'])
        if is_dup:
            log(" -> SKIP: Already queued.")
            continue
            
        queue_command(m['instruction'])
        
    # 2. Brainstorming
    # Run periodically (e.g. 50% chance or check time)
    # For now, we run it every time but check duplication
    new_idea = brainstorm_idea()
    if new_idea:
        log(f" [BRAIN] Proposed: {new_idea[:40]}...")
        # Debounce logic handled by check_duplicate if idea repeats, 
        # but for unique AI ideas, we might want to just queue it.
        queue_command(new_idea, origin="brain_hybrid")

if __name__ == "__main__":
    main()
