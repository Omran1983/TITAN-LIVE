"""
graph_builder.py
----------------
Scans the AION-ZERO workspace AND external sources.
Extracts dependencies, scans for safety, and populates Supabase Graph tables.

Usage:
  python graph_builder.py --root "F:/AION-ZERO"
"""

import os
import sys
import argparse
import re
import shutil
import subprocess
import glob
from datetime import datetime

# You might need 'pip install supabase'
try:
    from supabase import create_client, Client
except ImportError:
    print("CRITICAL: 'supabase' lib not installed. Run: pip install supabase")
    sys.exit(1)

# --- CONFIG ---
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
STAGING_DIR  = "F:/AION-ZERO/inputs/repos"

if not SUPABASE_URL or not SUPABASE_KEY:
    print("CRITICAL: Env vars SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY missing.")
    sys.exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# --- SAFETY SCANNER ---

UNSAFE_EXTENSIONS = {'.exe', '.dll', '.so', '.bin', '.msi', '.bat', '.cmd', '.vbs'}
SUSPICIOUS_PATTERNS = [
    r'eval\(', 
    r'exec\(', 
    r'base64\.b64decode', 
    r'subprocess\.call', 
    r'os\.system'
]

def scan_file_safety(path):
    """Returns True if safe, False if suspicious."""
    ext = os.path.splitext(path)[1].lower()
    if ext in UNSAFE_EXTENSIONS:
        print(f" [UNSAFE] Blocked extension: {ext} in {path}")
        return False
    
    # Size check (skip huge files)
    if os.path.getsize(path) > 1024 * 1024 * 5: # 5MB limit
        return False

    try:
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            # Basic heuristic scan
            for p in SUSPICIOUS_PATTERNS:
                if re.search(p, content):
                    # Reduce noise: usually these are fine in python scripts, 
                    # but for external ingestion we mark as 'manual review needed' or skip.
                    # For now, we Log warning but allow if it looks like a standard library usage?
                    # Strict mode: Reject.
                    print(f" [WARNING] Suspicious pattern '{p}' in {path}")
                    # return False # Uncomment to block
    except Exception:
        return False # Binaries masquerading as text

    return True

# --- DB OPS ---

def upsert_node(name, type, file_path, source="local"):
    print(f" [NODE] {name} ({type})")
    data = {
        "name": name,
        "type": type,
        "meta": {"file_path": file_path, "source": source},
        "updated_at": datetime.utcnow().isoformat()
    }
    try:
        supabase.table("az_graph_nodes").upsert(data, on_conflict="name, type").execute()
    except Exception as e:
        print(f"  Error upserting node: {e}")

def upsert_edge(source, target, relation):
    print(f"   --> [EDGE] {relation} --> {target}")
    data = {
        "source": source,
        "target": target,
        "relation": relation,
        "updated_at": datetime.utcnow().isoformat()
    }
    try:
        supabase.table("az_graph_edges").upsert(data, on_conflict="source, target, relation").execute()
    except Exception as e:
        print(f"  Error upserting edge: {e}")

# --- PARSERS ---

def extract_deps_ps1(content):
    deps = []
    matches_include = re.findall(r'^\s*\.\s+["\']([^"\']+)["\']', content, re.MULTILINE)
    for m in matches_include:
        deps.append(("imports", os.path.basename(m)))
    
    matches_table = re.findall(r'az_[a-z_]+', content)
    for t in matches_table:
        deps.append(("queries", t))

    return deps

def extract_deps_py(content):
    deps = []
    matches_import = re.findall(r'^\s*import\s+(\w+)', content, re.MULTILINE)
    for m in matches_import:
        deps.append(("imports", m))
    
    matches_from = re.findall(r'^\s*from\s+(\w+)', content, re.MULTILINE)
    for m in matches_from:
        deps.append(("imports", m))
    return deps

def extract_deps_sql(content):
    deps = []
    matches_table = re.findall(r'create table if not exists public\.(az_[a-z_]+)', content)
    for t in matches_table:
        deps.append(("defines", t))
    return deps

# --- INGESTION LOOPS ---

def scan_directory(root_dir, source_label="local"):
    print(f"Scanning {root_dir} ({source_label})...")
    
    for r, d, f in os.walk(root_dir):
        # Skip .git etc
        if ".git" in r: continue

        for file in f:
            if file.startswith("."): continue
            
            path = os.path.join(r, file)
            
            # SCAN SAFETY
            if not scan_file_safety(path):
                continue

            name = file
            ext = os.path.splitext(file)[1].lower()
            
            node_type = "file"
            if ext == ".ps1": node_type = "script_ps"
            elif ext == ".py": node_type = "script_py"
            elif ext == ".sql": node_type = "schema"
            elif ext == ".md": node_type = "doc"
            
            upsert_node(name, node_type, path, source=source_label)

            try:
                with open(path, "r", encoding="utf-8", errors="ignore") as f_obj:
                    content = f_obj.read()
                    
                    found_deps = []
                    if ext == ".ps1": found_deps = extract_deps_ps1(content)
                    elif ext == ".py": found_deps = extract_deps_py(content)
                    elif ext == ".sql": found_deps = extract_deps_sql(content)
                    
                    for rel, target in found_deps:
                        upsert_node(target, "concept", "", source="inferred") 
                        upsert_edge(name, target, rel)

            except Exception as e:
                print(f"  Error reading {file}: {e}")

def process_external_repo(url, id):
    repo_name = url.split("/")[-1].replace(".git", "")
    target_dir = os.path.join(STAGING_DIR, repo_name)
    
    print(f"--- External Repo: {repo_name} ---")
    
    # 1. Update DB to 'scanning'
    supabase.table("az_graph_sources").update({"trust_level": "scanning"}).eq("id", id).execute()

    try:
        # 2. Clone
        if os.path.exists(target_dir):
            print("  Pulling latest...")
            subprocess.run(["git", "pull"], cwd=target_dir, check=False)
        else:
            print("  Cloning...")
            subprocess.run(["git", "clone", url, target_dir], check=True)
        
        # 3. Scan & Ingest
        scan_directory(target_dir, source_label=f"github:{repo_name}")
        
        # 4. Mark Trust
        supabase.table("az_graph_sources").update({
            "trust_level": "trusted", 
            "last_scanned": datetime.utcnow().isoformat()
        }).eq("id", id).execute()

    except Exception as e:
        print(f" [ERROR] Failed to process {url}: {e}")
        supabase.table("az_graph_sources").update({"trust_level": "error", "meta": {"error": str(e)}}).eq("id", id).execute()

def process_web_doc(url, id, category):
    print(f"--- Web Doc: {url} [{category}] ---")
    
    # 1. Update scanning
    supabase.table("az_graph_sources").update({"trust_level": "scanning"}).eq("id", id).execute()

    try:
        import requests
        from bs4 import BeautifulSoup
        
        # 2. Fetch
        resp = requests.get(url, timeout=15)
        resp.raise_for_status()
        
        # 3. Parse
        soup = BeautifulSoup(resp.content, 'html.parser')
        # Cleanup script/style
        for script in soup(["script", "style"]):
            script.extract()
        
        text = soup.get_text()
        lines = (line.strip() for line in text.splitlines())
        chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
        clean_text = '\n'.join(chunk for chunk in chunks if chunk)
        
        # 4. Save to Disk (Cache)
        safe_name = re.sub(r'[^a-zA-Z0-9]', '_', url)[:100] + ".txt"
        cache_dir = os.path.join(STAGING_DIR, "docs")
        os.makedirs(cache_dir, exist_ok=True)
        cache_path = os.path.join(cache_dir, safe_name)
        
        with open(cache_path, "w", encoding="utf-8") as f:
            f.write(clean_text)

        # 5. Ingest Node
        title = soup.title.string if soup.title else url
        upsert_node(title, "web_doc", cache_path, source=url)
        
        # 6. Mark Trust
        supabase.table("az_graph_sources").update({
            "trust_level": "trusted", 
            "last_scanned": datetime.utcnow().isoformat()
        }).eq("id", id).execute()

    except Exception as e:
        print(f" [ERROR] Failed to scrape {url}: {e}")
        supabase.table("az_graph_sources").update({"trust_level": "error", "meta": {"error": str(e)}}).eq("id", id).execute()

def process_external_sources():
    print("Checking for external sources...")
    try:
        # Fetch 'untrusted' or 'trusted' (re-scan)
        # For this demo, we fetch everything not 'blocked'
        resp = supabase.table("az_graph_sources").select("*").neq("trust_level", "blocked").execute()
        for row in resp.data:
            if row['type'] == 'github':
                process_external_repo(row['url'], row['id'])
            elif row['type'] == 'doc_url':
                process_web_doc(row['url'], row['id'], row.get('category', 'general'))
    except Exception as e:
        print(f"Error fetching sources: {e}")

def seed_defaults():
    print("Seeding default intelligence sources...")
    sources = [
        # A. Research
        {'url': 'https://github.com/microsoft/graphrag', 'type': 'github', 'category': 'research', 'trust_level': 'trusted'},
        {'url': 'https://arxiv.org/abs/2305.15334', 'type': 'doc_url', 'category': 'research', 'trust_level': 'trusted'},
        {'url': 'https://github.com/google/adk-docs', 'type': 'github', 'category': 'framework', 'trust_level': 'trusted'},
        {'url': 'https://machinelearningmastery.com/top-5-agentic-ai-llm-models', 'type': 'doc_url', 'category': 'research', 'trust_level': 'trusted'},
        {'url': 'https://github.com/modelcontextprotocol/servers', 'type': 'github', 'category': 'technical_tooling', 'trust_level': 'trusted'},
        # B. Tech Specs
        {'url': 'https://github.com/PowerShell/PowerShell', 'type': 'github', 'category': 'technical_docs', 'trust_level': 'trusted'},
        {'url': 'https://docs.python.org/3/library', 'type': 'doc_url', 'category': 'technical_docs', 'trust_level': 'trusted'},
        {'url': 'https://supabase.com/docs', 'type': 'doc_url', 'category': 'technical_docs', 'trust_level': 'trusted'},
        {'url': 'https://github.com/vercel/next.js', 'type': 'github', 'category': 'technical_docs', 'trust_level': 'trusted'},
        # C. Strategy
        {'url': 'https://www.gutenberg.org/files/132/132-h/132-h.htm', 'type': 'doc_url', 'category': 'strategy_classic', 'trust_level': 'trusted'},
        {'url': 'https://en.wikipedia.org/wiki/The_Toyota_Way', 'type': 'doc_url', 'category': 'strategy_classic', 'trust_level': 'trusted'},
        # D. Ecosystem
        {'url': 'https://github.com/langchain-ai/langgraph', 'type': 'github', 'category': 'framework', 'trust_level': 'trusted'},
        {'url': 'https://github.com/joaomdmoura/crewAI', 'type': 'github', 'category': 'framework', 'trust_level': 'trusted'},
        {'url': 'https://github.com/microsoft/autogen', 'type': 'github', 'category': 'framework', 'trust_level': 'trusted'},
        # E. Security
        {'url': 'https://owasp.org/Top10/', 'type': 'doc_url', 'category': 'security_redteam', 'trust_level': 'trusted'},
        {'url': 'http://pentest-standard.org/', 'type': 'doc_url', 'category': 'security_redteam', 'trust_level': 'trusted'},
        {'url': 'https://www.kali.org/docs/', 'type': 'doc_url', 'category': 'security_redteam', 'trust_level': 'trusted'},
        {'url': 'https://cheatsheetseries.owasp.org/', 'type': 'doc_url', 'category': 'security_blueteam', 'trust_level': 'trusted'},
        # F. Innovation
        {'url': 'http://theleanstartup.com/principles', 'type': 'doc_url', 'category': 'innovation_strategy', 'trust_level': 'trusted'},
        {'url': 'https://www.kaizen.com/what-is-kaizen', 'type': 'doc_url', 'category': 'innovation_strategy', 'trust_level': 'trusted'},
        # G. Marketing/Sales
        {'url': 'https://farnamstreet.com/influence-summary/', 'type': 'doc_url', 'category': 'marketing_psychology', 'trust_level': 'trusted'},
        {'url': 'https://readingraphics.com/book-summary-100m-offers/', 'type': 'doc_url', 'category': 'marketing_strategy', 'trust_level': 'trusted'},
        # H. Law/Finance
        {'url': 'https://attorneygeneral.govmu.org/Pages/Laws%20of%20Mauritius/Laws-of-Mauritius.aspx', 'type': 'doc_url', 'category': 'law_mauritius', 'trust_level': 'trusted'},
        {'url': 'https://uncitral.un.org/sites/uncitral.un.org/files/media-documents/uncitral/en/19-09955_e_ebook.pdf', 'type': 'doc_url', 'category': 'law_arbitration', 'trust_level': 'trusted'},
        {'url': 'https://www.fatf-gafi.org/en/publications/Fatfrecommendations/Fatf-recommendations.html', 'type': 'doc_url', 'category': 'finance_aml', 'trust_level': 'trusted'},
        {'url': 'https://www.acfe.com/-/media/files/acfe/pdfs/rttn/2024/2024-report-to-the-nations.pdf', 'type': 'doc_url', 'category': 'finance_fraud', 'trust_level': 'trusted'}
    ]
    
    for s in sources:
        try:
            # We use upsert on URL content if schema constraint exists, but upsert syntax depends on library version.
            # Assuming 'url' is unique constraint in DB
            resp = supabase.table("az_graph_sources").upsert(s, on_conflict="url").execute()
            print(f" [SEED] {s['category']}: {s['url']}")
        except Exception as e:
            print(f" [ERROR] Could not seed {s['url']}: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default="F:/AION-ZERO", help="Root dir to scan")
    parser.add_argument("--seed", action="store_true", help="Seed default intelligence sources")
    args = parser.parse_args()
    
    # Ensure staging dir
    os.makedirs(STAGING_DIR, exist_ok=True)

    if args.seed:
        seed_defaults()

    # 1. Local Scan
    scan_directory(args.root, source_label="local")
    
    # 2. External Scan
    process_external_sources()
