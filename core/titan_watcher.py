
import time
import json
import sys
import uuid
from pathlib import Path
from datetime import datetime

# Add repository root to python path to allow absolute imports of 'core'
REPO_ROOT = Path(__file__).parent.parent
sys.path.append(str(REPO_ROOT))

# Now import from core
from core.governance.titan_registry import DIRECTORS, MANAGERS, BOTS, AUTONOMY_LOOP
from core.governance.titan_kernel import Requestor, AuthorityLevel, ExecutionPermitGateway, TitanExecutionEngine, Decree, ActionType

# PATHS
STATE_FILE = Path(__file__).parent / "state" / "system_state.json"
QUEUE_FILE = Path(__file__).parent / "state" / "mission_queue.json"

def ensure_state_dir():
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)

def update_state(state):
    ensure_state_dir()
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)

def read_queue():
    if QUEUE_FILE.exists():
        try:
            return json.loads(QUEUE_FILE.read_text())
        except:
            return []
    return []

def clear_queue():
    if QUEUE_FILE.exists():
        QUEUE_FILE.write_text("[]")

def main():
    print("⚡ TITAN WATCHER (v3.1): SYSTEM BOOT SEQUENCE INITIATED...")
    
    # Initialize Kernel Components
    gateway = ExecutionPermitGateway()
    titan = TitanExecutionEngine()

    system_state = {
        "status": "BOOTING",
        "last_updated": str(datetime.now()),
        "directors": [],
        "managers": [],
        "bots": [],
        "autonomy_loop": [],
        "active_bots": 0,
        "logs": [] # Execution Logs
    }
    
    # 1. HIRE DIRECTORS
    print("\n[🏛️ BOARD] Inducting Directors...")
    for d in DIRECTORS:
        d_rec = d.copy()
        d_rec["level"] = d["level"].name
        system_state["directors"].append(d_rec)

    # 2. HIRE MANAGERS
    print("\n[👔 MANAGERS] Activating Domain Owners...")
    for m in MANAGERS:
        m_rec = m.copy()
        m_rec["level"] = m["level"].name
        system_state["managers"].append(m_rec)

    # 3. HIRE BOTS
    print("\n[🤖 FLEET] Deploying Bot Fleet...")
    active_bot_count = 0
    # Map Bot ID back to full object (for Kernel lookup during execution)
    bot_map = {} 
    
    for bot_id, bot_data in BOTS.items():
        bot_record = bot_data.copy()
        bot_record["id"] = bot_id
        bot_record["level"] = bot_data["level"].name
        bot_record["status"] = "ONLINE"
        system_state["bots"].append(bot_record)
        
        # Hydrate Bot Object for Kernel (Requestor)
        bot_map[bot_id] = Requestor(bot_data['name'], bot_data['level'])
        active_bot_count += 1
    
    # 4. START AUTONOMY LOOP
    print("\n[🧬 AUTONOMY] Initializing Platform Loop...")
    for loop_bot in AUTONOMY_LOOP:
        system_state["autonomy_loop"].append(loop_bot)

    system_state["status"] = "ONLINE"
    system_state["active_bots"] = active_bot_count
    
    update_state(system_state)
    print(f"\n✅ SYSTEM ONLINE. {active_bot_count} Bots Active. Listening on {QUEUE_FILE}...")

    # --- MAIN EVENT LOOP ---
    try:
        while True:
            system_state["last_updated"] = str(datetime.now())
            
            # 1. Check Mission Queue
            queue = read_queue()
            if queue:
                print(f"[📥 INBOX] Processing {len(queue)} Missions...")
                
                for task in queue:
                    bot_id = task.get("bot_id")
                    requestor = bot_map.get(bot_id)
                    
                    if not requestor:
                        print(f"   [❌ ERROR] Unknown Bot ID: {bot_id}")
                        continue
                        
                    # Determine Action Type (Simplistic inference for demo)
                    # "Scrape" -> READ/LOG (Safe)
                    # "Spend" or "Buy" -> SPEND_MONEY
                    # "Update" or "Delete" -> WRITE_DB
                    content = task.get("content", "").lower()
                    amount = float(task.get("amount", 0.0))
                    
                    action_type = ActionType.READ # Default safe
                    if "buy" in content or "spend" in content or amount > 0:
                        action_type = ActionType.SPEND_MONEY
                    elif "update" in content or "delete" in content or "write" in content:
                        action_type = ActionType.WRITE_DB
                    elif "log" in content or "scrape" in content:
                        action_type = ActionType.WRITE_LOG

                    # Create Decree
                    decree = Decree(task["content"], action_type, requestor, amount)
                    
                    # ASK KERNEL
                    permit = gateway.request_permit(decree)
                    
                    # LOG RESULT
                    log_entry = {
                        "id": task["id"],
                        "timestamp": time.strftime("%H:%M:%S"),
                        "event": f"{requestor.name}: {task['content']}",
                        "status": "PENDING",
                        "details": ""
                    }
                    
                    if permit and permit.is_valid:
                        # EXECUTE
                        titan.execute(decree, permit)
                        log_entry["status"] = "✅ EXECUTED"
                        log_entry["details"] = f"Permit #{permit.id} Granted. Budget: ${amount}"
                    else:
                        # BLOCKED
                        log_entry["status"] = "⛔ BLOCKED"
                        log_entry["details"] = f"Authority Violation ({requestor.level.name})."
                    
                    # Prepend to logs
                    system_state["logs"].insert(0, log_entry)
                    # Keep logs trimmed
                    system_state["logs"] = system_state["logs"][:20]

                # Clear Queue after processing
                clear_queue()
                update_state(system_state)
            
            # Heartbeat Update
            if int(time.time()) % 5 == 0:
                update_state(system_state)
                
            time.sleep(2)
            
    except KeyboardInterrupt:
        print("\n[🛑 SHUTDOWN] Titan Watcher stopping...")
        system_state["status"] = "OFFLINE"
        update_state(system_state)

if __name__ == "__main__":
    main()
