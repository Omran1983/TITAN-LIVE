import requests
import json
import os
import argparse
from datetime import datetime
from pathlib import Path
import uuid

# -----------------------------
# CONFIG
# -----------------------------
TITAN_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = Path(__file__).parent / "data"
SIGNALS_PATH = DATA_DIR / "signals.jsonl"
ROADMAP_PATH = TITAN_ROOT / "az_roadmap.jsonl" # Central Brain

# Keyword Classifiers
KEYWORDS = {
    "REQUEST": ["looking for", "need a", "recommend a", "paying for", "hiring", "seeking"],
    "FUNDING": ["grant", "funding", "budget", "investment", "proposal call", "rfp", "tender"],
    "COMPLIANCE": ["compliance", "regulation", "audit", "reporting", "gdpr", "data protection"],
    "AUTOMATION": ["automate", "manual process", "tedious", "excel hell", "scrape"]
}

# -----------------------------
# ADAPTERS
# -----------------------------
class SourceAdapter:
    def fetch(self, limit=10):
        raise NotImplementedError

class MockSource(SourceAdapter):
    def fetch(self, limit=10):
        # Simulated "Reddit" or "ReliefWeb" hits
        return [
            {
                "source": "Mock/Reddit",
                "title": "Looking for a tool to automate monthly NGO reporting",
                "url": "http://reddit.com/r/ngo_tech",
                "text": "I spend 3 days a month doing manual excel reports for our donors. Is there a SaaS for this? Budget available."
            },
            {
                "source": "Mock/EDB",
                "title": "Call for Proposals: SME Digital Transformation",
                "url": "http://edb.mu/calls",
                "text": "Grant window open for SMEs implementing ERP or Cloud solutions. 50% refund."
            }
        ]

class ReliefWebSource(SourceAdapter):
    """Real implementation using ReliefWeb API (Free)"""
    def fetch(self, limit=5):
        try:
            url = "https://api.reliefweb.int/v1/jobs"
            params = {
                "appname": "TITAN_VOYAGER",
                "limit": limit,
                "preset": "latest",
                "query[value]": "reporting OR data OR automation"
            }
            resp = requests.get(url, params=params, timeout=10)
            if resp.status_code == 200:
                data = resp.json()
                results = []
                for job in data.get("data", []):
                    # Need secondary fetch for full text, but title is often enough for signal
                    results.append({
                        "source": "ReliefWeb",
                        "title": job["fields"]["title"],
                        "url": job["fields"]["url"],
                        "text": job["fields"]["title"] # Simplified
                    })
                return results
            return []
        except Exception as e:
            print(f"[VOYAGER] ReliefWeb Error: {e}")
            return []

# -----------------------------
# CORE LOGIC
# -----------------------------
def classify(text):
    text_lower = text.lower()
    tags = []
    
    for category, terms in KEYWORDS.items():
        if any(term in text_lower for term in terms):
            tags.append(category)
            
    return tags

def save_signal(signal):
    # 1. Raw Log
    with open(SIGNALS_PATH, "a", encoding="utf-8") as f:
        f.write(json.dumps(signal) + "\n")
        
    # 2. Roadmap Promotion (High Value Only)
    is_high_value = "REQUEST" in signal["tags"] or "FUNDING" in signal["tags"]
    if is_high_value:
        roadmap_entry = {
            "id": str(uuid.uuid4()),
            "type": "OPPORTUNITY",
            "title": signal["title"],
            "description": f"Detected by Voyager via {signal['source']}. Tags: {signal['tags']}",
            "status": "BACKLOG",
            "detected_at": signal["timestamp"]
        }
        with open(ROADMAP_PATH, "a", encoding="utf-8") as f:
            f.write(json.dumps(roadmap_entry) + "\n")
            print(f"[VOYAGER] [PROMO] Promoted to Roadmap: {signal['title']}")
        return roadmap_entry
    return None

def run_mission(sources=["mock"]):
    print(f"--- VOYAGER MISSION START: {datetime.now()} ---")
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    
    total_signals = 0
    promoted = []
    
    adapters = {
        "mock": MockSource(),
        "reliefweb": ReliefWebSource()
    }
    
    for src_name in sources:
        adapter = adapters.get(src_name)
        if not adapter:
            print(f"[WARN] Unknown source: {src_name}")
            continue
            
        print(f"[VOYAGER] Scanning Sector: {src_name}...")
        raw_items = adapter.fetch()
        
        for item in raw_items:
            tags = classify(item["title"] + " " + item["text"])
            if tags: # Only save relevant signals
                signal = {
                    "id": str(uuid.uuid4()),
                    "timestamp": datetime.now().isoformat(),
                    "source": item["source"],
                    "url": item["url"],
                    "title": item["title"],
                    "tags": tags,
                    "raw_text": item["text"]
                }
                promoted_item = save_signal(signal)
                total_signals += 1
                if promoted_item:
                    promoted.append(promoted_item)
    
    # Canonical Envelope
    response = {
        "ok": True,
        "request_id": str(uuid.uuid4()),
        "ts": datetime.now().isoformat(),
        "agent": "Voyager",
        "severity": "info",
        "human_summary": f"Captured {total_signals} signals. Promoted {len(promoted)} high-value opportunities to roadmap.",
        "findings": [{"id": p["id"], "title": p["title"]} for p in promoted], # Just showing promoted findings
        "actions": promoted, # The action was "promotion"
        "metrics": {
            "scanned_sources": len(sources),
            "signals_captured": total_signals,
            "signals_promoted": len(promoted)
        }
    }
    print(json.dumps(response, indent=2))
    print(f"--- VOYAGER MISSION END: Captured {total_signals} Signals ---")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", default="mock,reliefweb", help="Comma-sep sources")
    args = parser.parse_args()
    
    src_list = args.source.split(",")
    run_mission(src_list)
