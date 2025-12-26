import os
import sys
import uuid
import asyncio
import json
from wildfire.core.utils import SupabaseClient

sys.path.append("F:\\AION-ZERO\\TITAN")

async def inject():
    sb = SupabaseClient()
    cid = str(uuid.uuid4())
    
    print(f">>> INJECTING OUTCOME A TEST (SYSTEM HEALTH AUDIT) [{cid}] <<<")

    cmd = {
        "command_id": cid,
        "origin": "telegram",
        "source_chat_id": "123456789", 
        "requested_by": "founder",
        
        "title": "Internal Run 1: System Health Audit",
        "intent": "v2.run_workflow", # Maps to Conductor
        "objective": "Execute Outcome A internal test 1/5",
        
        "inputs": {
            "workflow_type": "outcome_a_system_health", # Links to Outcome Registry
            "mode": "internal_test"
        },
        "targets": [], 
        "constraints": [],
        
        "state": "QUEUED",
        "priority": 1
    }
    
    res = sb.insert("az_commands", cmd)
    print("Injected.")

if __name__ == "__main__":
    asyncio.run(inject())
