
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
DB_URL = os.environ.get("JARVIS_DB_CONN")

def apply():
    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        with open(r"f:\AION-ZERO\sql\az_roadmap.sql", "r", encoding="utf-8") as f:
            sql = f.read()
            
        cur.execute(sql)
        conn.commit()
        print("✅ Schema Applied Successfully.")
        conn.close()
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    apply()
