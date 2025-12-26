import json
import os
import sys
import uuid
import time
from datetime import datetime
from pathlib import Path

# -----------------------------
# CONFIG / PATHS
# -----------------------------
def resolve_titan_root() -> Path:
    env_root = os.environ.get("TITAN_ROOT")
    if env_root:
        return Path(env_root).resolve()
    # Fallback: assuming apps/doctor/doctor.py -> ../../
    return Path(__file__).resolve().parents[2]

TITAN_ROOT = resolve_titan_root()
DOCTOR_DIR = Path(__file__).parent
LEDGER_PATH = DOCTOR_DIR / "ledger.jsonl"
SCHEMAS_DIR = DOCTOR_DIR / "schemas"

# Input Report
REPORT_PATH = TITAN_ROOT / "apps" / "inspector" / "reports" / "latest" / "audit.json"

# Target for restart fix
BRIDGE_API_PATH = TITAN_ROOT / "bridge" / "bridge_api.py"

# -----------------------------
# PLAYBOOK
# -----------------------------
PLAYBOOK = {
    "JOURNEY_FAILURE": ["restart_service", "clear_cache"],
    "GRANT_GENERATION_FAIL": ["restart_service"], # Critical Money Machine Failure
    "CONSOLE_EXCEPTION": ["restart_service"],
    "DEAD_LINK": ["noop"], # Can't fix code remotely yet
    "NETWORK_FAILURE": ["restart_service"]
}

# -----------------------------
# HELPERS
# -----------------------------
def now_iso() -> str:
    return datetime.now().astimezone().isoformat()

def load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"[ERROR] Failed to load {path}: {e}")
        return {}

def append_ledger(entry: dict):
    """Immutable append to ledger"""
    try:
        with open(LEDGER_PATH, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry) + "\n")
        print(f"[LEDGER] Recorded entry: {entry['entry_id']}")
    except Exception as e:
        print(f"[CRITICAL] Ledger Write Failed: {e}")

# -----------------------------
# ACTIONS
# -----------------------------
def action_restart_service() -> dict:
    """Touches bridge_api.py to trigger Uvicorn reload"""
    print("[ACTION] Restarting Service (Touching bridge_api.py)...")
    try:
        if not BRIDGE_API_PATH.exists():
            return {"outcome": "FAILED", "notes": "bridge_api.py not found"}
        
        # Read content and write it back to update mtime
        content = BRIDGE_API_PATH.read_text(encoding="utf-8")
        BRIDGE_API_PATH.write_text(content, encoding="utf-8")
        
        return {"outcome": "SUCCESS", "notes": "Triggered reload via filesystem touch"}
    except Exception as e:
        return {"outcome": "FAILED", "notes": str(e)}

def action_clear_cache() -> dict:
    print("[ACTION] Clearing Cache (Simulated)...")
    return {"outcome": "SUCCESS", "notes": "Cache cleared (simulated)"}

def action_noop() -> dict:
    print("[ACTION] No-op (Awareness only)")
    return {"outcome": "SUCCESS", "notes": "No action required or allowed"}

# -----------------------------
# CORE LOGIC
# -----------------------------
def analyze_signals(report: dict) -> list:
    signals = []
    
    # 1. Overall Status Check
    if report.get("status") == "PASS":
        return []

    # 2. Journey Failures
    for j in report.get("journeys", []):
        if j["status"] != "PASS":
            signals.append({
                "signal_id": str(uuid.uuid4()),
                "signal_type": "JOURNEY_FAILURE",
                "severity": "HIGH",
                "scope": j.get("name", "unknown"),
                "evidence": [j.get("error", "Unknown error")],
                "confidence": 1.0
            })

    # 3. Console Errors
    if report.get("console_errors"):
        signals.append({
            "signal_id": str(uuid.uuid4()),
            "signal_type": "CONSOLE_EXCEPTION",
            "severity": "MEDIUM",
            "scope": "frontend",
            "evidence": report["console_errors"][:3], # Limit evidence
            "confidence": 1.0
        })
        
    # 4. Network Failures (if any left after filtering)
    if report.get("network_failures"):
        signals.append({
            "signal_id": str(uuid.uuid4()),
            "signal_type": "NETWORK_FAILURE",
            "severity": "MEDIUM",
            "scope": "network",
            "evidence": report["network_failures"][:3],
            "confidence": 0.9
        })

    return signals

def main():
    print("--- TITAN DOCTOR v1.0 ---")
    
    # 1. Load Report
    print(f"Reading Report: {REPORT_PATH}")
    report = load_json(REPORT_PATH)
    response = {
        "ok": True,
        "request_id": str(uuid.uuid4()),
        "ts": now_iso(),
        "agent": "Doctor",
        "severity": "info",
        "human_summary": "No report found or empty. Doctor is standing by.",
        "findings": [],
        "actions": [],
        "metrics": {"signals": 0, "actions": 0}
    }

    if not report:
        print(json.dumps(response, indent=2))
        return

    # 2. Diagnostics
    print(f"Report Status: {report.get('status', 'UNKNOWN')}")
    signals = analyze_signals(report)
    
    if not signals:
        print("[HEALTHY] No signals to process. System is Green.")
        return

    print(f"[SICK] Found {len(signals)} signals.")

    # 3. Treatment Loop
    actions_taken = []
    
    for sig in signals:
        sig_type = sig["signal_type"]
        
        # Check Playbook
        allowed = PLAYBOOK.get(sig_type, ["noop"])
        selected_action = allowed[0] # V1: Always pick first preferred action
        
        # Execute
        start_time = time.time()
        result = {"outcome": "ABORTED", "notes": "Unknown action"}
        
        if selected_action == "restart_service":
            result = action_restart_service()
        elif selected_action == "clear_cache":
            result = action_clear_cache()
        elif selected_action == "noop":
            result = action_noop()
            
        duration = int((time.time() - start_time) * 1000)
        
        # Log to Ledger
        entry = {
            "entry_id": str(uuid.uuid4()),
            "signal_id": sig["signal_id"],
            "signal_type": sig_type,
            "action": selected_action,
            "actor": "DOCTOR",
            "result": result["outcome"],
            "notes": result["notes"],
            "duration_ms": duration,
            "timestamp": now_iso()
        }
        append_ledger(entry)
        actions_taken.append(entry)

    # 4. Final Report
    severity = "info"
    if signals:
        severity = "warn"
        if any(a["result"] != "SUCCESS" for a in actions_taken):
            severity = "critical"

    summary = f"Processed {len(signals)} signals. Took {len(actions_taken)} actions."
    if actions_taken:
        action_strs = [f"{a['action']} ({a['result']})" for a in actions_taken]
        summary += f" Actions: {', '.join(action_strs)}."
    else:
        summary += " System is healthy."

    response = {
        "ok": True,
        "request_id": str(uuid.uuid4()),
        "ts": now_iso(),
        "agent": "Doctor",
        "severity": severity,
        "human_summary": summary,
        "findings": signals,
        "actions": actions_taken,
        "metrics": {
            "signals": len(signals),
            "actions": len(actions_taken)
        }
    }
    print(json.dumps(response, indent=2))

if __name__ == "__main__":
    main()
