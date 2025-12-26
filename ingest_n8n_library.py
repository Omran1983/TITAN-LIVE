import os
import json
import psycopg2
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()
DB_URL = os.environ.get("JARVIS_DB_CONN")
LIB_DIR = Path(r"f:\AION-ZERO\data\n8n-library")
SQL_FILE = r"f:\AION-ZERO\sql\init_n8n_library.sql"

def setup_db(conn):
    print("--- Applying Schema...")
    with open(SQL_FILE, 'r') as f:
        sql = f.read()
    with conn.cursor() as cur:
        cur.execute(sql)
    conn.commit()

def extract_metadata(data):
    nodes = set()
    creds = set()
    name = "Unknown"

    if isinstance(data, dict):
        name = data.get('name', "Unknown")
        # n8n workflows have a "nodes" array
        for node in data.get('nodes', []):
            if 'type' in node:
                nodes.add(node['type'])
            if 'credentials' in node:
                # credentials is a dict like {'stripeApi': ...}
                for k in node['credentials'].keys():
                    creds.add(k)
    return name, list(nodes), list(creds)

def ingest():
    if not DB_URL:
        print("[FAIL] No DB URL")
        return

    try:
        conn = psycopg2.connect(DB_URL)
        setup_db(conn)
        
        print(f"--- Scanning {LIB_DIR}...")
        count = 0
        batch = []
        batch_size = 100

        cur = conn.cursor()

        json_files = list(LIB_DIR.rglob("*.json"))
        print(f"   Found {len(json_files)} JSON files. Indexing...")

        for p in json_files:
            try:
                with open(p, 'r', encoding='utf-8', errors='ignore') as f:
                    content = json.load(f)
                
                name, nodes, creds = extract_metadata(content)
                
                # Check if gold (simple heuristic for now)
                is_gold = False 

                batch.append((
                    p.name,
                    str(p),
                    name,
                    json.dumps(nodes),
                    json.dumps(creds),
                    is_gold
                ))

                if len(batch) >= batch_size:
                    args_str = ','.join(cur.mogrify("(%s,%s,%s,%s,%s,%s)", x).decode('utf-8') for x in batch)
                    cur.execute("INSERT INTO az_n8n_workflows (filename, filepath, name, nodes, credentials, is_gold) VALUES " + args_str)
                    conn.commit()
                    count += len(batch)
                    print(f"   Indexed {count}...")
                    batch = []

            except Exception as e:
                print(f"   [WARN] Error reading {p.name}: {e}")

        # Final batch
        if batch:
            args_str = ','.join(cur.mogrify("(%s,%s,%s,%s,%s,%s)", x).decode('utf-8') for x in batch)
            cur.execute("INSERT INTO az_n8n_workflows (filename, filepath, name, nodes, credentials, is_gold) VALUES " + args_str)
            conn.commit()
            count += len(batch)

        print(f"[SUCCESS] Ingestion Complete. Total: {count}")
        cur.close()
        conn.close()

    except Exception as e:
        print(f"[FAIL] Error: {e}")

if __name__ == "__main__":
    ingest()
