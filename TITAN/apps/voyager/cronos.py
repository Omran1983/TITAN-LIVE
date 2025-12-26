import time
import subprocess
import sys
import shutil
import ctypes
import os
import json
from pathlib import Path
from datetime import datetime

# -----------------------------
# CONFIG
# -----------------------------
TITAN_ROOT = Path(__file__).resolve().parents[2]
LOG_FILE = TITAN_ROOT / "apps" / "voyager" / "data" / "system.log"
LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
VOYAGER_SCRIPT = TITAN_ROOT / "apps" / "voyager" / "voyager.py"
DISK_THRESHOLD_GB = 2.0  # Alert if free space < 2GB
CHECK_INTERVAL_SEC = 3600 # Run every hour (Production)

# -----------------------------
# SYSTEM HELPERS
# -----------------------------
def log(msg):
    """Prints to console and appends to log file."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{timestamp}] {msg}"
    print(formatted)
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(formatted + "\n")
    except Exception as e:
        print(f"[CRONOS] ⚠️ Log Write Failed: {e}")

def prevent_sleep():
    """Prevents Windows from sleeping while this script is running."""
    try:
        # ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED
        ctypes.windll.kernel32.SetThreadExecutionState(0x80000000 | 0x00000001 | 0x00000002)
        log("[CRONOS] 🔋 Sleep prevention active.")
    except Exception as e:
        log(f"[CRONOS] ⚠️ Failed to set sleep prevention: {e}")

def check_disk_space(drives=["C:", "F:"]):
    """Checks disk space and alerts if low."""
    status = {}
    for drive in drives:
        try:
            if not os.path.exists(drive):
                continue
            total, used, free = shutil.disk_usage(drive)
            free_gb = free // (2**30)
            status[drive] = free_gb
            
            if free_gb < DISK_THRESHOLD_GB:
                log(f"[CRONOS] 🚨 LOW DISK SPACE ON {drive}: {free_gb}GB FREE")
                # TODO: Trigger Doctor signal 'LOW_DISK_SPACE'
            else:
                log(f"[CRONOS] 💾 {drive} Space: {free_gb}GB Free (OK)")
        except Exception as e:
            log(f"[CRONOS] ⚠️ Failed to check {drive}: {e}")
    return status

def run_voyager():
    """Executes the Voyager scraper agent."""
    log(f"[CRONOS] 🚀 Launching Voyager...")
    try:
        # Run python apps/voyager/voyager.py
        result = subprocess.run(
            [sys.executable, str(VOYAGER_SCRIPT)], 
            capture_output=True, 
            text=True
        )
        if result.returncode == 0:
            log("[CRONOS] ✅ Voyager finished successfully.")
            # log(result.stdout)
        else:
            log(f"[CRONOS] ❌ Voyager failed (Code {result.returncode})")
            log(result.stderr)
    except Exception as e:
        log(f"[CRONOS] 💥 System Error running Voyager: {e}")

# -----------------------------
# MAIN LOOP
# -----------------------------
def main():
    log("--- ⏳ TITAN CRONOS: 24/7 SUPERVISOR ---")
    log(f"Root: {TITAN_ROOT}")
    prevent_sleep()
    
    while True:
        log(f"\n[TICK] Starting Cycle...")
        
        # 1. Health Checks
        check_disk_space()
        
        # 2. Run Worker (Voyager)
        if VOYAGER_SCRIPT.exists():
            run_voyager()
        else:
            log(f"[CRONOS] ⚠️ Voyager script not found at {VOYAGER_SCRIPT}")
            
        # 3. Wait
        log(f"[CRONOS] 💤 Sleeping for {CHECK_INTERVAL_SEC}s...")
        time.sleep(CHECK_INTERVAL_SEC)

if __name__ == "__main__":
    main()
