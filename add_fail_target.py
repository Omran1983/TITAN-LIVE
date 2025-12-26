
import os
from dotenv import load_dotenv

load_dotenv()
url = os.environ.get("VITE_SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_KEY")

try:
    from supabase import create_client, Client
    supabase: Client = create_client(url, key)
    
    res = supabase.table("az_uptime_targets").insert({
        "name": "Titan Fail Test",
        "url": "https://titan-fail-test-domain-xyz.com",
        "contact_email": "test_draft@titan.com",
        "is_active": True
    }).execute()
    
    print(f"✅ Added Fail Target: {res.data[0]['id']}")
    
except Exception as e:
    print(f"Error: {e}")
