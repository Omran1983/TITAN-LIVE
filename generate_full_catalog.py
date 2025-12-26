import os
import psycopg2
from dotenv import load_dotenv

load_dotenv(r"f:\AION-ZERO\.env")
DB_URL = os.environ.get("JARVIS_DB_CONN")
OUTPUT_FILE = r"f:\AION-ZERO\n8n_library_full_catalog.md"

def generate_catalog():
    if not DB_URL:
        print("[FAIL] No DB URL")
        return

    try:
        conn = psycopg2.connect(DB_URL)
        cur = conn.cursor()
        
        # Fetch all workflows
        cur.execute("SELECT name, filename, nodes FROM az_n8n_workflows ORDER BY name ASC")
        rows = cur.fetchall()
        
        print(f"--- Fetching {len(rows)} workflows...")
        
        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            f.write("# n8n Workflow Library - Full Catalog\n\n")
            f.write(f"**Total Count:** {len(rows)}\n")
            f.write("This document contains the complete list of ingested n8n workflows available in Titan's memory.\n\n")
            
            f.write("| Workflow Name | Filename | Key Nodes |\n")
            f.write("|---|---|---|\n")
            
            for r in rows:
                name = r[0] or "Unknown"
                # Clean name (remove newlines if any)
                name = name.replace("\n", " ").strip()
                filename = r[1]
                nodes_json = r[2] # This comes as a list/dict depending on how psycopg2 handles jsonb
                
                # Extract interesting nodes (filter out common ones mostly?)
                # Actually, let's just list the first 3-5 unique node types to keep it readable
                node_list = []
                if isinstance(nodes_json, list):
                    node_list = list(set([n.replace("n8n-nodes-base.", "") for n in nodes_json]))
                
                # Filter out boring nodes
                ignored = {'Start', 'StickyNote', 'NoOp', 'Set', 'Merge'}
                filtered_nodes = [n for n in node_list if n not in ignored]
                
                nodes_str = ", ".join(filtered_nodes[:4])
                if len(filtered_nodes) > 4:
                    nodes_str += ", ..."
                
                f.write(f"| {name} | `{filename}` | {nodes_str} |\n")
        
        print(f"[SUCCESS] Catalog generated at {OUTPUT_FILE}")
        conn.close()

    except Exception as e:
        print(f"[FAIL] Error: {e}")

if __name__ == "__main__":
    generate_catalog()
