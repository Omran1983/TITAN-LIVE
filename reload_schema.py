
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

DB_URL = os.environ.get("JARVIS_DB_CONN")

def reload_schema():
    if not DB_URL:
        print("❌ JARVIS_DB_CONN not found in .env")
        return

    print(f"Connecting to DB...")
    try:
        conn = psycopg2.connect(DB_URL)
        conn.autocommit = True
        cur = conn.cursor()
        
        print("Notifying PostgREST to reload schema...")
        cur.execute("NOTIFY pgrst, 'reload schema';")
        
        print("Reload Signal Sent.")
        
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Database Error: {e}")

if __name__ == "__main__":
    reload_schema()
