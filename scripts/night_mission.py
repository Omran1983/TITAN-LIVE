import time
import requests
import json

# ==========================================
# 🌙 TITAN NIGHT MISSION: "DEEP OBSERVER"
# ==========================================
# This script commands the Titan 5-Cycle Agent to acquiring knowledge while you sleep.
# It uses the "titan:website_review" governed capability.

API_URL = "http://127.0.0.1:5000/api/agents/website-review"
TOKEN = "OPERATOR"

# 🎯 MISSION TARGETS
# Add the URLs you want Titan to study/monitor tonight.
TARGETS = [
    "https://news.ycombinator.com",
    "https://techcrunch.com/category/artificial-intelligence/",
    "https://dev.to/t/python",
    "https://github.com/trending",
    # Add your specific business competitors or research topics here:
    # "https://competitor.com",
]

def log(msg, symbol="ℹ️"):
    print(f"{symbol} [{time.strftime('%H:%M:%S')}] {msg}")

def run_mission():
    print("\n🌌 STARTING TITAN NIGHT MISSION [Review Protocol]...\n")
    
    success_count = 0
    
    for url in TARGETS:
        log(f"Acquiring Target: {url}", "🔭")
        
        try:
            # Execute 5-Cycle Agent (Observe -> Acquire -> Persist -> Index -> Act)
            resp = requests.post(
                API_URL, 
                json={"url": url},
                headers={"Authorization": f"Bearer {TOKEN}"},
                timeout=30
            )
            
            if resp.status_code == 200:
                data = resp.json()
                if data.get("ok"):
                    log(f"SUCCESS: Analyzed {url}", "✅")
                    log(f"  -> Artifact Hash: {data.get('persist', {}).get('hash', 'N/A')}")
                    log(f"  -> Capabilities: {json.dumps(data.get('index', {}).get('signals', {}))}")
                    success_count += 1
                else:
                    log(f"FAILURE: Logic Error - {data.get('error')}", "⚠️")
            else:
                log(f"FAILURE: HTTP {resp.status_code} - {resp.text}", "🛑")
                
        except Exception as e:
            log(f"CRITICAL: {str(e)}", "❌")
            
        # Respect Governance Cooldown (simulated processing time)
        log("Cooling down / Processing...", "⏳")
        time.sleep(5) 

    print(f"\n🌙 MISSION COMPLETE.")
    print(f"📊 Summary: {success_count}/{len(TARGETS)} targets acquired.")
    print(f"📂 Evidence: Check 'Capabilities' and 'Artifacts' in Glass Citadel UI.\n")

if __name__ == "__main__":
    run_mission()
