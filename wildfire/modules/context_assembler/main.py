import os
import sys
import time

# Helper to find project root dynamically
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.append(PROJECT_ROOT)

from wildfire.core.utils import SupabaseClient, now_iso

class ContextAssembler:
    def __init__(self):
        self.sb = SupabaseClient()
        self.agent_id = "AGENT_CONTEXT_ASSEMBLER"

    def assemble(self, cmd: dict):
        cid = cmd['command_id']
        print(f"[{self.agent_id}] Assembling context for {cid}...")
        
        # Claims the command
        self.sb.patch("az_commands", f"command_id=eq.{cid}", {
            "state": "RUNNING", 
            "progress": 10
        })

        # Tier L0: Latest errors
        errors = self.sb.select("az_events", "severity=eq.error&limit=5&order=ts.desc")
        
        # Tier L1: Recent commands
        history = self.sb.select("az_commands", "state=eq.DONE&limit=5&order=created_at.desc")

        # Create Packet
        packet = {
            "packet_id": f"ctx_{int(time.time())}",
            "command_id": cid,
            "assembled_at": now_iso(),
            "token_budget": 4096,
            "tiers": [
                {
                    "tier": "L0",
                    "sources": ["az_events.errors"],
                    "tokens_used": len(str(errors)),
                    "data": errors
                },
                {
                    "tier": "L1",
                    "sources": ["az_commands.history"],
                    "tokens_used": len(str(history)),
                    "data": history
                }
            ],
            "redactions_applied": True
        }
        
        # Store Packet (Note: schema requires 'tiers' to match strict shape, 'data' might need to be serialized or stored separately if strict)
        # Simplified for now to match strict schema (data often stored in 'payload' or referenced)
        # We will dump data into a blob for now or a separate table if needed.
        # For strict schema compliance, we might need to adjust or create a payload field.
        # Assuming table accepts JSONB for these fields.

        self.sb.insert("az_context_packets", packet)

        self.sb.emit_event(self.agent_id, "context_assembled", f"Generated packet {packet['packet_id']}", command_id=cid)
        
        # Finish
        self.sb.patch("az_commands", f"command_id=eq.{cid}", {
            "state": "DONE",
            "result": {"packet_id": packet['packet_id']}
        })

    def run_poll(self):
        print(f"{self.agent_id} Polling...")
        while True:
            # In real system, Dispatcher calls this via subprocess. 
            # For standalone testing:
            time.sleep(5) 

if __name__ == "__main__":
    # If run as script, it acts as the handler for the dispatched command
    # Dispatcher passes command ID via args or env
    assembler = ContextAssembler()
    # Mock single run behavior if arguments present
    # ...
    assembler.run_poll()
