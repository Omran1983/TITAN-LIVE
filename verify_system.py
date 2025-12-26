import json
import glob
import time
import sys
import importlib.util
from pathlib import Path
from datetime import datetime

# Map User's "Modules" to our actual folder structure
# "site_health" -> apps/inspector + apps/doctor
# "grants_eligibility" -> apps/grant_writer
MODULE_MAP = {
    "site_health": ["apps/inspector/inspector.py", "apps/doctor/doctor.py"],
    "grants_eligibility": ["apps/grant_writer/tinns_generator.py"],
    "voyager_engine": ["apps/voyager/voyager.py"],
    "utils": ["apps/utils/summarize_cli.py"],
    "policy_core": ["policy/authority.toml", "policy/decision_atoms.json"]
}
PROJECTS_ROOT = Path("../projects")

def verify_file_exists(path: Path) -> dict:
    if path.exists():
        return {"ok": True, "path": str(path)}
    return {"ok": False, "error": f"File not found: {path}"}

def run_module_check(mod_name: str, files: list) -> dict:
    results = []
    all_ok = True
    
    for fpath in files:
        full_path = Path.cwd() / fpath
        res = verify_file_exists(full_path)
        if not res["ok"]:
            all_ok = False
        results.append(res)
        
    return {
        "module": mod_name,
        "ok": all_ok,
        "checks": results
    }

def main():
    print("--- TITAN VERIFICATION HARNESS ---")
    start_time = time.time()
    
    report = {
        "ok": True,
        "request_id": f"verify-{int(start_time)}",
        "ts": datetime.now().astimezone().isoformat(),
        "agent": "VerificationHarness",
        "severity": "info",
        "human_summary": "",
        "findings": [],
        "metrics": {}
    }

    modules_checked = []
    
    for mod, files in MODULE_MAP.items():
        res = run_module_check(mod, files)
        modules_checked.append(res)
        if not res["ok"]:
            report["ok"] = False
            report["severity"] = "warn"

    # Scan Projects
    projects_found = []
    if PROJECTS_ROOT.exists():
        for p in PROJECTS_ROOT.iterdir():
            if p.is_dir():
                projects_found.append(p.name)
    
    report["findings"] = {
        "modules": modules_checked,
        "projects_scanned": projects_found
    }
    
    failed_mods = [m["module"] for m in modules_checked if not m["ok"]]
    if failed_mods:
        report["human_summary"] = f"Verification Failed for: {', '.join(failed_mods)}"
    else:
        report["human_summary"] = f"All {len(modules_checked)} core modules verified. Found {len(projects_found)} active projects."
        
    # Save Log
    log_dir = Path("logs")
    log_dir.mkdir(exist_ok=True)
    out_file = log_dir / f"verify_{int(start_time)}.json"

    out_file.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))
    print(f"\nWrote report to {out_file}")

if __name__ == "__main__":
    main()
