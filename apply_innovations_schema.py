
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
DB_URL = os.environ.get("JARVIS_DB_CONN")

def apply_schema():
    if not DB_URL:
        print("❌ JARVIS_DB_CONN not found.")
        return

    sql_file = r"f:\AION-ZERO\sql\az_innovations.sql"
    
    try:
        with open(sql_file, "r") as f:
            sql = f.read()
            
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        cur.execute(sql)
        conn.commit()
        
        print("✅ Schema Applied: az_innovations table created.")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"❌ Failed to apply schema: {e}")

if __name__ == "__main__":
    apply_schema()
