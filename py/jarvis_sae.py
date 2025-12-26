"""
JARVIS SELF-AUDIT ENGINE (S.A.E.)
---------------------------------
Phase 18: The Mirror Protocol
Role:
1. Scans system logs for errors, latency, and instability.
2. Generates a daily health report.
3. Feeds the 'Architect' module.
"""

import os
import json
import re
from datetime import datetime, timedelta

# --- CONFIG ---
LOG_DIR = r"F:\AION-ZERO\logs"
WATCHDOG_LOG = r"F:\AION-ZERO\scripts\Jarvis-Watchdog.log"
REPORT_DIR = r"F:\AION-ZERO\reports\self_audit"

def parse_watchdog_log():
    """Analyzes Watchdog logs for crashes and restart events."""
    issues = []
    performance_metrics = {"uptime_checks": 0, "failures": 0}
    
    if not os.path.exists(WATCHDOG_LOG):
        return {"status": "missing_log", "issues": ["Watchdog log not found"]}
        
    try:
        with open(WATCHDOG_LOG, "r", encoding="utf-8") as f:
            lines = f.readlines()
            
        # Parse last 24h (approx last 1000 lines to be safe/fast)
        recent_lines = lines[-1000:] 
        
        for line in recent_lines:
            if "ERROR" in line or "Failed" in line:
                issues.append({"type": "error", "source": "Watchdog", "details": line.strip()})
                performance_metrics["failures"] += 1
            if "Restarting" in line:
                 issues.append({"type": "instability", "source": "Watchdog", "details": "Service Restart Detected"})
            
            performance_metrics["uptime_checks"] += 1
            
    except Exception as e:
        issues.append({"type": "internal_error", "details": str(e)})
        
    return {"issues": issues, "metrics": performance_metrics}

def generate_audit_report():
    print("[SAE] Starting System Self-Audit...")
    
    # 1. Analyze Components
    wd_analysis = parse_watchdog_log()
    
    # 2. Compile Report
    report = {
        "timestamp": datetime.now().isoformat(),
        "integrity_status": "STABLE" if wd_analysis["metrics"]["failures"] == 0 else "DEGRADED",
        "metrics": {
            "watchdog": wd_analysis["metrics"]
        },
        "detected_inefficiencies": wd_analysis["issues"],
        "recommendations": []
    }
    
    # 3. Simple Heuristic Recommendations (The "Pre-Architect" Logic)
    if wd_analysis["metrics"]["failures"] > 5:
        report["recommendations"].append({
            "component": "Watchdog",
            "action": "investigate_logs",
            "priority": "high",
            "reason": "High failure rate detected in Watchdog."
        })
        
    # 4. Save
    if not os.path.exists(REPORT_DIR):
        os.makedirs(REPORT_DIR)
        
    filename = f"{REPORT_DIR}\\audit_{datetime.now().strftime('%Y%m%d')}.json"
    with open(filename, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)
        
    print(f"[SAE] Audit Complete. Report saved to: {filename}")
    if report["detected_inefficiencies"]:
        print(f" -> Found {len(report['detected_inefficiencies'])} issues.")
    else:
        print(" -> System is Green.")

if __name__ == "__main__":
    generate_audit_report()
