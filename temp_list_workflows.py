import os
import psycopg2
from dotenv import load_dotenv

load_dotenv(r"f:\AION-ZERO\.env")
DB_URL = os.environ.get("JARVIS_DB_CONN")

def list_workflows():
    if not DB_URL:
        print("Error: No DB URL")
        return

    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        # Get Total Count
        cur.execute("SELECT count(*) FROM az_n8n_workflows")
        count = cur.fetchone()[0]
        print(f"# n8n Workflow Library Catalog\n**Total Items:** {count}\n")
        
        print("## Sample Workflows (First 100)")
        cur.execute("SELECT name, filename FROM az_n8n_workflows LIMIT 100")
        for row in cur.fetchall():
            name = row[0] or "Unnamed"
            print(f"- **{name}** (`{row[1]}`)")
            
        print("\n## Categories (Inferred from subfolders)")
        # This assumes filepath structure, if flat it won't help.
        # Let's check distinct nodes instead as a proxy for "category"
        
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    list_workflows()
