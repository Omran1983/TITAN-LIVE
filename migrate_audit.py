
import os
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

load_dotenv()
DB_URL = os.environ.get("JARVIS_DB_CONN")

DDL = """
CREATE TABLE IF NOT EXISTS az_audit_log (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    actor TEXT NOT NULL,
    action TEXT NOT NULL,
    tool TEXT NOT NULL,
    risk_level TEXT DEFAULT 'L1',
    status TEXT NOT NULL,
    payload JSONB DEFAULT '{}'::jsonb,
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_audit_ts ON az_audit_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_audit_action ON az_audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_tool ON az_audit_log(tool);
"""

def migrate():
    print("Connecting to DB...")
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    try:
        print("Executing DDL...")
        cur.execute(DDL)
        conn.commit()
        print("az_audit_log table created successfully.")
    except Exception as e:
        conn.rollback()
        print(f"Error: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    migrate()
