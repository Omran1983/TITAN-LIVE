import os
import sys
import uuid
import asyncio
import json
from wildfire.core.utils import SupabaseClient

sys.path.append("F:\\AION-ZERO\\TITAN")

async def inject():
    print(">>> INJECTING REVENUE RUN COMMAND (FINAL FIX) <<<")
    sb = SupabaseClient()
    
    cid = str(uuid.uuid4())
    
    # Must match schema constraints (NOT NULL columns)
    cmd = {
        "command_id": cid,
        "origin": "telegram",
        "source_chat_id": "123456789", 
        "requested_by": "founder",
        
        # REQUIRED FIELDS
        "title": "Running First Grant Workflow",
        "intent": "v2.run_workflow",
        "objective": "Execute the grant factory workflow manually via injection.",
        
        # JSONB Fields
        "inputs": {
            "workflow_type": "WF_GRANT_FACTORY", 
            "url": "https://example.com/grant.pdf"
        },
        "targets": [], 
        "constraints": [],
        
        "state": "QUEUED",
        "priority": 1
    }
    
    try:
        res = sb.insert("az_commands", cmd)
        print(f"Injected Command: {cid}")
        print(f"Result: {json.dumps(res, indent=2)}")
    except Exception as e:
        print(f"Injection Failed: {e}")

if __name__ == "__main__":
    asyncio.run(inject())
