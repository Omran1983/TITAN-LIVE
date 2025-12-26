import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

DB_DSN = os.environ.get("JARVIS_DB_CONN")
conn = psycopg2.connect(DB_DSN)
cur = conn.cursor()
cur.execute("SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'chk_az_agent_runs_status'")
rows = cur.fetchall()
if rows:
    print(rows[0][0])
else:
    print("Constraint not found via pg_constraint.")

cur.close()
conn.close()
