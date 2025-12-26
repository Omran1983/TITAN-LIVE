
import sys
import os
import json

# Add py to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'py')))
from jarvis_brain_local import JarvisBrain

def verify_memory():
    print("--- STARTING MEMORY VERIFICATION ---")
    brain = JarvisBrain()
    
    # 1. Read initial count
    initial_actions = brain.ledger["system_stats"].get("total_actions", 0)
    print(f"Initial Actions: {initial_actions}")
    
    # 2. Execute Tool
    print("Executing 'RunCommand'...")
    res = brain.execute_tool("RunCommand", {"command": "echo 'Memory Test'"})
    print(f"Tool Result: {res.strip()}")
    
    # 3. Read Ledger from Disk (to confirm write)
    with open(brain.ledger_path, "r") as f:
        data = json.load(f)
    
    final_actions = data["system_stats"].get("total_actions", 0)
    print(f"Final Actions: {final_actions}")
    
    if final_actions > initial_actions:
        print("PASS: Ledger updated successfully.")
    else:
        print("FAIL: Ledger did not increment.")

if __name__ == "__main__":
    verify_memory()
