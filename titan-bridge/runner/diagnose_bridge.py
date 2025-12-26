import os
import asyncio
from supabase import create_client, Client

# Load env vars manually if needed, or rely on system env
url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

if not url or not key:
    print("❌ Critical: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set in environment.")
    print("Run setup_env.bat first!")
    exit(1)

async def check_health():
    print(f"CONNECTING TO: {url}")
    supabase: Client = create_client(url, key)
    
    try:
        # 1. Check Connection / Tables
        print("\n--- 1. Checking Tables ---")
        # 1. Check Connection / Tables
        print("\n--- 1. Checking Tables ---")
        tables = ["az_commands", "az_events", "az_health_snapshots"]
        for t in tables:
            try:
                res = supabase.table(t).select("*", count="exact").limit(1).execute()
                print(f"✅ {t}: EXISTS ({res.count} rows)")
            except Exception:
                print(f"❌ {t}: NOT FOUND")
            
        # 2. Check for Queued Commands
        print("\n--- 2. Checking Recent Commands ---")
        try:
            # Check last 5 commands regardless of state
            recent = supabase.table("az_commands").select("*").order("created_at", desc=True).limit(5).execute()
            print(f"Recent Commands: {len(recent.data)}")
            for i, q in enumerate(recent.data):
                print(f" - [{q['state']}] {q['command_id']} : {q['title']}")
                if i == 0 and q['state'] == 'DONE':
                     print(f"   LATEST RESULT: {q.get('result', {})}")
        except Exception as e:
            print(f"❌ Queue check failed: {e}")
            
        # 3. Checking Runner Health
        print("\n--- 3. Checking Runner Health ---")
        try:
            health = supabase.table("az_health_snapshots").select("*").execute()
            print(f"Runner Snapshots: {len(health.data)}")
            for h in health.data:
                print(f" - {h['agent_id']}: {h['status']} (Last seen: {h['ts']})")
        except Exception as e:
            print(f"❌ Runner health check failed: {e}")

    except Exception as e:
        print(f"❌ ERROR: {e}")

if __name__ == "__main__":
    asyncio.run(check_health())
