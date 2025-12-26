
import os
from collections import Counter
from urllib.parse import urlparse
from dotenv import load_dotenv

load_dotenv()
url = os.environ.get("VITE_SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_KEY")

def get_tld(url):
    try:
        domain = urlparse(url).netloc
        if not domain: return "unknown"
        parts = domain.split('.')
        if len(parts) >= 1:
            return "." + parts[-1]
    except:
        pass
    return "unknown"

try:
    from supabase import create_client, Client
    supabase: Client = create_client(url, key)
    
    print("1. 📥 Fetching Targets...")
    res = supabase.table("az_uptime_targets").select("*").execute()
    targets = res.data
    
    if not targets:
        print("   Checking DB... 0 targets found.")
    else:
        print(f"   found {len(targets)} targets.\n")
        
        print("2. 🌍 Country/TLD Breakdown:")
        tlds = [get_tld(t['url']) for t in targets]
        counts = Counter(tlds)
        for tld, count in counts.most_common():
            print(f"   - {tld}: {count}")
            
        print("\n3. 📋 Target List (Recent 10):")
        for t in targets[-10:]:
             email_status = "✅ Has Email" if t.get('contact_email') else "❌ No Email"
             print(f"   [{t['id']}] {t['name'][:30]}... ({t['url']}) - {email_status}")

except Exception as e:
    print(f"Error: {e}")
