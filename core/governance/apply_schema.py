
import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Load .env (checking typical locations)
load_dotenv(Path(__file__).parent.parent.parent / '.env')

try:
    from supabase import create_client, Client
except ImportError:
    print("❌ 'supabase' library not found. Please install it: pip install supabase")
    sys.exit(1)

# Get Credentials
url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_KEY")
service_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY") # Prioritize service key for schema changes if available

target_key = service_key or key

if not url or not target_key:
    print("❌ Missing SUPABASE_URL or SUPABASE_KEY/SUPABASE_SERVICE_ROLE_KEY in .env")
    print(f"URL: {url}")
    print(f"Key Found: {'Yes' if target_key else 'No'}")
    sys.exit(1)

print(f"🔌 Connecting to Supabase: {url}")
supabase: Client = create_client(url, target_key)

# Read SQL
sql_path = Path(__file__).parent / "TITAN_Supabase_Schema.sql"
if not sql_path.exists():
    print(f"❌ SQL file not found: {sql_path}")
    sys.exit(1)

sql_content = sql_path.read_text(encoding="utf-8")

print("\n📜 Applying Schema...")
try:
    # Supabase-py 'rpc' is for functions. To run raw SQL we usually need the 'sql' endpoint or pg driver.
    # HOWEVER, the standard supabase-js/py client doesn't expose a raw 'query' method for safety, 
    # unless we use the 'postgres' connection string or a custom RPC.
    
    # Workaround: If we cannot run raw SQL via the client easily without an RPC, 
    # we can try to use 'postgrest' (unlikely for DDL) or check if we have psycopg2 installed.
    
    # Strategy: Try to use direct Postgres connection via psycopg2 if available, using the DB URL.
    # The DB URL usually looks like: postgres://postgres:[PASSWORD]@db.[REF].supabase.co:5432/postgres
    
    db_url = os.getenv("DATABASE_URL")
    if db_url:
        import psycopg2
        print(f"🔌 Connecting via psycopg2 to DATABASE_URL...")
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        cur.execute(sql_content)
        conn.commit()
        cur.close()
        conn.close()
        print("✅ Schema applied successfully via psycopg2.")
    else:
        print("⚠️ DATABASE_URL not found. Cannot apply DDL (CREATE TABLE) via 'supabase-py' REST client directly.")
        print("Please run the SQL manually in the Supabase SQL Editor.")
        sys.exit(1)

except ImportError:
    print("❌ 'psycopg2' not found. Cannot run raw SQL. Install: pip install psycopg2-binary")
    sys.exit(1)
except Exception as e:
    print(f"❌ Error applying schema: {e}")
    sys.exit(1)
