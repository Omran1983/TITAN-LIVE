import os
import time
import yaml
import subprocess
import glob
import sys
from .utils import SupabaseClient, now_iso, PROJECT_ROOT

from wildfire.modules.governor import Governor

class WildfireDispatcher:
    def __init__(self):
        self.sb = SupabaseClient()
        self.manifests = self.load_manifests()
        self.running_processes = {}
        self.governor = Governor()

    def load_manifests(self):
        # ... (unchanged)
        manifests = {}
        path = os.path.join(PROJECT_ROOT, "wildfire", "manifests", "agents", "*.yaml")
        for f in glob.glob(path):
            with open(f, 'r') as yml:
                try:
                    m = yaml.safe_load(yml)
                    manifests[m['agent_id']] = m
                except Exception as e:
                    print(f"Failed to load manifest {f}: {e}")
        return manifests

    def map_intent_to_agent(self, intent: str) -> str:
        clean_intent = intent.replace("v2.", "")
        mapping = {
            "inspect": "AGENT_INSPECTOR",
            "fix": "AGENT_DOCTOR",
            "ingest": "AGENT_INGESTION_HYDRA",
            "run_workflow": "AGENT_WORKFLOW_CONDUCTOR",
            "remote": "AGENT_REMOTE_BRIDGE",
            "route": "AGENT_BITNET_ROUTER"
        }
        return mapping.get(clean_intent)

    def dispatch(self, cmd: dict):
        cid = cmd['command_id']
        raw_intent = cmd.get('intent', '')
        intent = raw_intent.split('.')[0] 
        
        agent_id = self.map_intent_to_agent(raw_intent)
        if not agent_id:
            return 

        print(f"[{cid}] Evaluating Governance for {raw_intent}...")
        
        # --- GOVERNANCE CHECK ---
        # 1. Determine Authority Level needed
        # Defaults: L0 (observe), L2 (execute), L3 (spend/post)
        req_level = "L2" 
        if "post" in raw_intent or "spend" in raw_intent:
            req_level = "L3"
        if "kill" in raw_intent:
            req_level = "L4"
            
        action_context = {
            "intent": raw_intent,
            "required_level": req_level,
            "inputs": cmd.get('inputs', {}),
            "cost": 0, # Future: estimate cost
            "outcomes": [] # Future: parse outcomes
        }
        
        approval = self.governor.approve(action_context)
        
        if not approval["approved"]:
            print(f"[{cid}] BLOCKED by Governor: {approval['reason']}")
            self.fail_command(cid, f"Governor Blocked: {approval['reason']}")
            self.sb.emit_event("governor", cid, "warn", "blocked", f"Action blocked: {approval['reason']}", approval)
            return
            
        print(f"[{cid}] APPROVED by Governor. Dispatching to {agent_id}...")

        # 1. Claim it
        self.sb.patch("az_commands", f"command_id=eq.{cid}", {
            "state": "CLAIMED",
            "assigned_agent_id": agent_id,
            "progress": 1
        })
        self.sb.emit_event("wildfire_dispatcher", "dispatch", f"Routed to {agent_id}", command_id=cid)

        # 2. Launch Sandbox Process
        manifest = self.manifests.get(agent_id)
        if not manifest:
            self.fail_command(cid, f"Manifest not found for {agent_id}")
            return

        entrypoint = manifest['runtime']['entrypoint']
        # Mock launch logic remains same
        self.sb.emit_event("wildfire_dispatcher", "sandbox_start", f"Started {entrypoint}", command_id=cid)
        
        # In real Phase C, we would subprocess.Popen here
    
    def fail_command(self, cid, reason):
        self.sb.patch("az_commands", f"command_id=eq.{cid}", {
            "state": "FAILED",
            "error": {"message": reason}
        })

    def run_loop(self):
        print("Wildfire Dispatcher v2.0 Active. Polling for 'v2.*'...")
        while True:
            try:
                # Wildfire Runner: Only v2.* intents
                cmds = self.sb.select("az_commands", "state=eq.QUEUED&intent=like.v2.*&limit=1&order=created_at.asc")
                if cmds:
                    self.dispatch(cmds[0])
                time.sleep(2)
            except Exception as e:
                print(f"Dispatcher Loop Error: {e}")
                time.sleep(5)

if __name__ == "__main__":
    WildfireDispatcher().run_loop()
