import os
import sys
import uuid
import asyncio
import json
import time
from wildfire.core.utils import SupabaseClient

sys.path.append("F:\\AION-ZERO\\TITAN")

async def inject_batch():
    sb = SupabaseClient()
    print(">>> INJECTING RUNS 2-5 (OUTCOME A) <<<")

    for i in range(2, 6):
        cid = str(uuid.uuid4())
        cmd = {
            "command_id": cid,
            "origin": "telegram",
            "source_chat_id": "123456789", 
            "requested_by": "founder",
            "title": f"Internal Run {i}: System Health Audit",
            "intent": "v2.run_workflow",
            "objective": f"Execute Outcome A internal test {i}/5",
            "inputs": {
                "workflow_type": "outcome_a_system_health",
                "mode": "internal_test"
            },
            "targets": [], 
            "constraints": [],
            "state": "QUEUED",
            "priority": 1
        }
        sb.insert("az_commands", cmd)
        print(f"Injected Run {i}: {cid}")
        time.sleep(0.5)

if __name__ == "__main__":
    asyncio.run(inject_batch())
