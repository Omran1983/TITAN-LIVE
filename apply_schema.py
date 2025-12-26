import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

DB_URL = os.environ.get("JARVIS_DB_CONN")
SQL_FILE = r"f:\AION-ZERO\sql\init_a2ui.sql"

def apply_schema():
    if not DB_URL:
        print("[FAIL] JARVIS_DB_CONN not found in .env")
        return

    if not os.path.exists(SQL_FILE):
        print(f"[FAIL] SQL file not found: {SQL_FILE}")
        return

    print(f"--- Connecting to DB...")
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        with open(SQL_FILE, "r") as f:
            sql_content = f.read()
            
        print("--- Applying Schema...")
        cur.execute(sql_content)
        conn.commit()
        
        print("[SUCCESS] Schema Applied Successfully.")
        
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"[FAIL] Database Error: {e}")

if __name__ == "__main__":
    apply_schema()
