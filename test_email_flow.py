
import os
import sys
from dotenv import load_dotenv

load_dotenv()
url = os.environ.get("VITE_SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_KEY")
user_email = os.environ.get("SMTP_USER")

try:
    from supabase import create_client, Client
    supabase: Client = create_client(url, key)
    
    print("1. 🔍 Checking DB Schema Visibility...")
    # Explicitly ask for contact_email to force error if missing
    try:
        res = supabase.table("az_uptime_targets").select("id, name, contact_email").limit(1).execute()
        print(f"   ✅ Columns visible: {res.data[0].keys()}")
    except Exception as e:
        print(f"   ⚠️ Schema Issue: {e}")

    print("\n2. 📝 Creating TEST DRAFT...")
    payload = {
        "target_id": None, # Nullable? Hopefully. If not, we need a valid target ID.
        "channel": "email",
        "recipient": user_email, # Send to self
        "subject": "Titan SMTP Test: It Works! 🦅",
        "body": "This is a test email sent from your Titan Autonomous Agent.\n\nTime: " + os.popen("time /t").read(),
        "status": "draft"
    }
    
    # We need a valid target_id if FK constraint exists. 
    # Let's get the fail target id
    fres = supabase.table("az_uptime_targets").select("id").eq("name", "Titan Fail Test").execute()
    if fres.data:
        payload['target_id'] = fres.data[0]['id']
    else:
        # Fallback to any
        r = supabase.table("az_uptime_targets").select("id").limit(1).execute()
        if r.data:
             payload['target_id'] = r.data[0]['id']
    
    draft_res = supabase.table("az_outreach_queue").insert(payload).execute()
    draft_id = draft_res.data[0]['id']
    print(f"   ✅ Draft Created! ID: {draft_id}")
    
    print("\n3. 🚀 Sending Email via titan_sender.py...")
    # Import sender locally to use its logic
    from titan_sender import send_draft
    success = send_draft(draft_id)
    
    if success:
        print("\n🎉 SUCCESS: Test Email Sent to " + user_email)
    else:
        print("\n❌ FAIL: Could not send email.")

except Exception as e:
    print(f"❌ Error: {e}")
