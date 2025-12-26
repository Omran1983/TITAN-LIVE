
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

DB_URL = os.environ.get("JARVIS_DB_CONN")
SQL_FILE = r"f:\AION-ZERO\sql\az_client_nabmakeup.sql"

def apply_nab_schema():
    if not DB_URL or not os.path.exists(SQL_FILE):
        print("❌ Config/File missing.")
        return

    print(f"🔌 Connecting to DB...")
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        with open(SQL_FILE, "r") as f:
            sql_content = f.read()
            
        print("📜 Applying NabMakeup Schema...")
        cur.execute(sql_content)
        conn.commit()
        
        print("✅ Client 'NabMakeup' Initialized.")
        
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Database Error: {e}")

if __name__ == "__main__":
    apply_nab_schema()
