
import os
import sys
import requests
from bs4 import BeautifulSoup
import re
from dotenv import load_dotenv

load_dotenv()
url = os.environ.get("VITE_SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_KEY")

def find_email_simple(target_url):
    try:
        r = requests.get(target_url, timeout=10)
        soup = BeautifulSoup(r.text, 'html.parser')
        emails = set(re.findall(r"[a-z0-9\.\-+_]+@[a-z0-9\.\-+_]+\.[a-z]+", soup.text, re.I))
        valid = [e for e in emails if not e.endswith(('png', 'jpg'))]
        return valid[0] if valid else None
    except:
        return None

def add_manual_target(target_url, name):
    try:
        from supabase import create_client, Client
        supabase: Client = create_client(url, key)
        
        print(f"🔎 Scanning {target_url} for contact info...")
        email = find_email_simple(target_url)
        print(f"   Shape: {email if email else 'No email found (Manual entry required)'}")
        
        payload = {
            "name": name,
            "url": target_url,
            "contact_email": email,
            "check_interval": 15, # Aggressive monitoring for hot lead
            "is_active": True
        }
        
        res = supabase.table("az_uptime_targets").insert(payload).execute()
        print(f"✅ Added {name} to Titan Monitor [ID: {res.data[0]['id']}]")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    # Usage: python add_single_target.py "https://nabmakeup.com/" "NAB Makeup"
    if len(sys.argv) > 2:
        add_manual_target(sys.argv[1], sys.argv[2])
    else:
        # Default for this turn
        add_manual_target("https://nabmakeup.com/", "NAB Makeup")
