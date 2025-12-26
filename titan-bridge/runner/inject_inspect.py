import asyncio
import uuid
import json
import time
from httpx import AsyncClient

# HARDCODED CONFIG FOR RELIABILITY
SUPABASE_URL = "https://abkprecmhitqmmlzxfad.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia3ByZWNtaGl0cW1tbHp4ZmFkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTk0NzY1OSwiZXhwIjoyMDc1NTIzNjU5fQ.-NrAHBNJOefsKpN_UIKhHNSukh7-ABO13IQjfNLswY4"

headers = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

async def inject_and_monitor():
    cmd_id = str(uuid.uuid4())
    payload = {
        "command_id": cmd_id,
        "intent": "project.run",
        "title": "TEST RUN inspect (Output Capture)",
        "objective": "TEST RUN inspect",
        "inputs": {"project_id": "titan_inspect"},
        "priority": 1,
        "state": "QUEUED",
        "source_chat_id": "debug_console"
    }

    url = f"{SUPABASE_URL}/rest/v1/az_commands"
    
    async with AsyncClient() as client:
        print(f"Injecting command {cmd_id}...")
        try:
            r = await client.post(url, headers=headers, json=payload)
            if r.status_code >= 300:
                print(f"Error injecting: {r.text}")
                return
        except Exception as e:
            print(f"Injection Failed: {e}")
            return

        print("Waiting for runner...")
        for _ in range(60): # Wait 120 seconds max
            try:
                r = await client.get(f"{url}?command_id=eq.{cmd_id}&select=state,progress,result,error", headers=headers)
                rows = r.json()
                if not rows: continue
                
                cmd = rows[0]
                state = cmd['state']
                print(f"Status: {state} {cmd.get('progress',0)}%")
                
                if state in ('DONE', 'FAILED'):
                    print("\n--- FINAL RESULT ---")
                    print(json.dumps(cmd, indent=2))
                    
                    # Fetch Events to show Logs
                    ev_url = f"{SUPABASE_URL}/rest/v1/az_events?command_id=eq.{cmd_id}&event_type=eq.log&select=message&order=ts.asc"
                    evs = await client.get(ev_url, headers=headers)
                    print("\n--- LOGS ---")
                    for e in evs.json():
                        print(e.get("message", ""))
                    return
            except Exception as e:
                print(f"Poll Error: {e}")
            
            await asyncio.sleep(2)

if __name__ == "__main__":
    asyncio.run(inject_and_monitor())
