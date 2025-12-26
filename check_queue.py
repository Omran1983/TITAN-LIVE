
import os
from dotenv import load_dotenv

load_dotenv()
url = os.environ.get("VITE_SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_KEY")

try:
    from supabase import create_client, Client
    supabase: Client = create_client(url, key)
    
    res = supabase.table("az_outreach_queue").select("*").execute()
    
    if not res.data:
        print("📭 Queue is Empty.")
    else:
        print(f"📬 Queue contains {len(res.data)} drafts:")
        for email in res.data:
            print(f"   - [ID: {email['id']}] To: {email['recipient']} | Subject: {email['subject']}")
            print(f"     Status: {email['status']}")
            print("     ---")
            
except Exception as e:
    print(f"Error: {e}")
