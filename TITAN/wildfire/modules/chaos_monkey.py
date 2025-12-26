import random
import time
import json
import sys
import os

# Add Project Root to Path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../")))

from wildfire.core.utils import SupabaseClient

class ChaosMonkey:
    """
    The Agent of Entropy.
    Intentionally breaks things to test system resilience.
    Actions:
    1. kill_agent: Simulates an agent crash.
    2. corrupt_command: Injects malformed JSON.
    3. network_lag: Sleeps to simulate timeout.
    """
    def __init__(self):
        self.sb = SupabaseClient()
        self.agent_id = "AGENT_CHAOS"

    def execute_chaos(self, mode: str):
        print(f"[{self.agent_id}] Unleashing Chaos Mode: {mode}")
        
        if mode == "bad_input":
            # Inject a command with missing required fields to test Governor/Dispatcher
            bad_cmd = {
                "command_id": f"chaos_{int(time.time())}",
                "origin": "chaos_monkey",
                # Missing 'intent', 'title'
                "state": "QUEUED"
            }
            try:
                self.sb.insert("az_commands", bad_cmd)
                print("Injected Malformed Command (Should fail schema validation)")
            except Exception as e:
                print(f"System resilient! DB blocked insert: {e}")

        elif mode == "governor_stress":
            # Inject a command requiring L5 authority (impossible) to test Governor
            # This requires a valid intent but high priv
            cmd = {
                "command_id": f"chaos_gov_{int(time.time())}",
                "origin": "chaos_monkey",
                "title": "Chaos L5 Attempt",
                "intent": "v2.kill_system", # mapped to L4/L5 in Governor
                "state": "QUEUED",
                "priority": 0
            }
            res = self.sb.insert("az_commands", cmd)
            print(f"Injected Hostile Command: {res}")
            
    def run_suite(self):
        self.execute_chaos("bad_input")
        self.execute_chaos("governor_stress")

if __name__ == "__main__":
    ChaosMonkey().run_suite()
