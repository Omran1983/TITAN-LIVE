
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

DB_URL = os.environ.get("JARVIS_DB_CONN")

def fix_schema():
    if not DB_URL:
        print("❌ JARVIS_DB_CONN not found in .env")
        return

    print(f"🔌 Connecting to DB...")
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        # Add column if missing
        print("📜 Altering Table (Adding contact_email)...")
        try:
            cur.execute("ALTER TABLE az_uptime_targets ADD COLUMN contact_email text;")
            conn.commit()
            print("✅ Column Added.")
        except psycopg2.errors.DuplicateColumn:
            conn.rollback()
            print("⚠️ Column already exists.")
            
        # Add Outreach Queue table if missing (apply_schema might have done this, but good to be sure)
        # We can just re-run the create table part for the queue, but apply_schema should have handled the new table. 
        # Main issue was the EXISTING table not getting the NEW column.
        
        # Update fail target with email just in case it was inserted without it
        cur.execute("UPDATE az_uptime_targets SET contact_email = 'test_draft@titan.com' WHERE name = 'Titan Fail Test';")
        conn.commit()
        print("✅ Fail Target Updated.")
        
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Database Error: {e}")

if __name__ == "__main__":
    fix_schema()
