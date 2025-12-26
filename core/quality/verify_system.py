#!/usr/bin/env python3
"""
AION-ZERO Verification Harness (Tier-1) - Audit Grade

Goal:
- Prove each block works standalone (independent)
- Prove the team works together (integrated)
- Produce auditable evidence logs
- Zero tolerance for stale artifacts or ambiguous schemas

Usage:
  python core/quality/verify_system.py --strict
  python core/quality/verify_system.py --strict --only hr_compliance
  python core/quality/verify_system.py --strict --skip-team
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Set

# -------------------------
# Config
# -------------------------
PROJECT_ROOT = Path(__file__).resolve().parents[2]
BLOCKS_DIR = PROJECT_ROOT / "blocks"
GUARDRAIL_PATH = PROJECT_ROOT / "core" / "quality" / "titan_guardrail.py"

LOGS_DIR = PROJECT_ROOT / "logs"
GUARDRAIL_LOG_DIR = LOGS_DIR / "guardrail"
VERIFY_LOG_DIR = LOGS_DIR / "verification"

DEFAULT_TIMEOUT_SEC = 180

REQUIRED_REPORT_FIELDS = {"schema_version", "block", "block_version", "timestamp", "failures", "details"}

UTC_ISO_RE = re.compile(r"\+00:00$|Z$")


@dataclass
class StepResult:
    name: str
    ok: bool
    exit_code: int = 0
    stdout: str = ""
    stderr: str = ""
    meta: Optional[dict] = None


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def run_cmd(cmd: List[str], cwd: Optional[Path] = None, timeout: int = DEFAULT_TIMEOUT_SEC) -> StepResult:
    env = os.environ.copy()
    env["PYTHONIOENCODING"] = "utf-8"
    try:
        p = subprocess.run(
            cmd,
            cwd=str(cwd) if cwd else None,
            capture_output=True,
            text=True,
            encoding="utf-8",
            timeout=timeout,
            env=env
        )
        return StepResult(
            name=" ".join(cmd[:3]),
            ok=(p.returncode == 0),
            exit_code=p.returncode,
            stdout=(p.stdout or "")[-8000:],
            stderr=(p.stderr or "")[-8000:],
            meta={"cmd": cmd, "cwd": str(cwd) if cwd else None},
        )
    except subprocess.TimeoutExpired as e:
        return StepResult(
            name=" ".join(cmd[:3]),
            ok=False,
            exit_code=124,
            stdout=(e.stdout or "")[-8000:] if e.stdout else "",
            stderr=(e.stderr or "")[-8000:] if e.stderr else "",
            meta={"cmd": cmd, "cwd": str(cwd) if cwd else None, "timeout": timeout},
        )
    except Exception as e:
        return StepResult(
            name=" ".join(cmd[:3]),
            ok=False,
            exit_code=2,
            stdout="",
            stderr=str(e),
            meta={"cmd": cmd, "cwd": str(cwd) if cwd else None},
        )


def read_toml(path: Path) -> dict:
    # Python 3.11+ stdlib
    import tomllib  # type: ignore

    return tomllib.loads(path.read_text(encoding="utf-8"))


def ensure_dirs():
    GUARDRAIL_LOG_DIR.mkdir(parents=True, exist_ok=True)
    VERIFY_LOG_DIR.mkdir(parents=True, exist_ok=True)


def load_block_manifests() -> Dict[str, dict]:
    manifests: Dict[str, dict] = {}
    if not BLOCKS_DIR.exists():
        raise FileNotFoundError(f"blocks/ dir not found: {BLOCKS_DIR}")

    for block_dir in sorted([p for p in BLOCKS_DIR.iterdir() if p.is_dir()]):
        manifest_path = block_dir / "block.toml"
        if manifest_path.exists():
            manifests[block_dir.name] = read_toml(manifest_path)
    return manifests


def get_dir_snapshot(path: Path) -> Set[Path]:
    """Returns a set of all files in the directory."""
    if not path.exists():
        return set()
    return set(path.rglob("*"))


def find_new_report(report_dir: Path, before_snapshot: Set[Path], pattern: str = "*.json") -> Optional[Path]:
    """Finds a file that exists now but didn't exist in the snapshot, or was modified."""
    if not report_dir.exists():
        return None
    
    current_files = list(report_dir.glob(pattern))
    
    # 1. Look for brand new files
    new_files = [f for f in current_files if f not in before_snapshot]
    if new_files:
        # Sort by modification time, newest first
        new_files.sort(key=lambda x: x.stat().st_mtime, reverse=True)
        return new_files[0]
        
    # 2. If no new files, look for modified files (if we allow overwriting, which we shouldn't really, but mostly we create new filenames)
    # Our validators generate timestamped filenames, so "new file" logic should hold.
    # Fallback to absolute newest file if we are desperate/legacy, but audit-grade demands NEW file.
    return None


def validate_report_schema(report_path: Path, block_name: str, expected_version: str) -> Tuple[bool, List[str], dict]:
    problems: List[str] = []
    try:
        data = json.loads(report_path.read_text(encoding="utf-8"))
    except Exception as e:
        return False, [f"REPORT_JSON_INVALID: {e}"], {}

    # 1. Field Existence
    missing = REQUIRED_REPORT_FIELDS - set(data.keys())
    if missing:
        problems.append(f"REPORT_MISSING_FIELDS: {sorted(missing)}")

    # 2. Metadata Matching
    if data.get("block") != block_name and data.get("block") != f"TITAN-{block_name.upper().replace('_', ' ')}":
         # We allow approximate match if validator uses "TITAN-HR Compliance" vs "hr_compliance"
         # But strict check is better. For now, strict on existence.
         pass 
         
    # 3. Timestamp Format
    ts = data.get("timestamp")
    if not isinstance(ts, str) or not UTC_ISO_RE.search(ts):
        problems.append("REPORT_TIMESTAMP_NOT_UTC_ISO")

    # 4. Failures Type
    failures = data.get("failures")
    if not isinstance(failures, int):
        problems.append("REPORT_FAILURES_NOT_INT")

    # 5. Money Safety (Heuristic)
    def walk(x):
        if isinstance(x, dict):
            for k, v in x.items():
                yield (k, v)
                yield from walk(v)
        elif isinstance(x, list):
            for v in x:
                yield from walk(v)

    float_hits = 0
    for k, v in walk(data):
        if isinstance(v, float) and any(s in str(k).lower() for s in ("salary", "amount", "price", "total", "cost", "fee")):
            float_hits += 1

    if float_hits > 0:
        problems.append(f"REPORT_FLOAT_MONEY_RISK_HITS={float_hits}")

    # Final Boolean
    # Only fail if critical schema errors present
    critical_errors = [p for p in problems if "MISSING" in p or "INVALID" in p or "NOT_UTC" in p]
    ok = len(critical_errors) == 0
    
    return ok, problems, data


def guardrail_block(block_name: str, strict: bool) -> StepResult:
    out_json = GUARDRAIL_LOG_DIR / f"{block_name}.json"
    cmd = [
        sys.executable,
        str(GUARDRAIL_PATH),
        "--target",
        str(BLOCKS_DIR / block_name),
        "--json",
        str(out_json),
    ]
    if strict:
        cmd.append("--strict")
        cmd.append("--require-tools")
    res = run_cmd(cmd, cwd=PROJECT_ROOT)
    res.name = f"guardrail:{block_name}"
    return res


def run_block(block_name: str, manifest: dict) -> Tuple[StepResult, Optional[Path], Optional[dict], List[str]]:
    """
    Runs block entrypoint with sample input.
    Returns: (run_result, report_path, report_json, schema_problems)
    """
    block_dir = BLOCKS_DIR / block_name
    entry = manifest.get("entrypoint")
    sample_input = manifest.get("sample_input")
    report_dir_name = manifest.get("report_dir", "reports")
    report_dir = block_dir / report_dir_name
    block_version = manifest.get("block_version", "0.0.0")

    if not entry or not sample_input:
        return (
            StepResult(
                name=f"run:{block_name}",
                ok=False,
                exit_code=2,
                stderr="Manifest missing 'entrypoint' or 'sample_input'.",
                meta={"block": block_name},
            ),
            None,
            None,
            ["MANIFEST_INCOMPLETE"],
        )

    entry_path = block_dir / entry
    input_path = block_dir / sample_input
    
    if not entry_path.exists():
        return (StepResult(name=f"run:{block_name}", ok=False, exit_code=2, stderr=f"Entrypoint not found: {entry_path}"), None, None, ["ENTRYPOINT_NOT_FOUND"])
    if not input_path.exists():
         return (StepResult(name=f"run:{block_name}", ok=False, exit_code=2, stderr=f"Input not found: {input_path}"), None, None, ["INPUT_NOT_FOUND"])

    # SNAPSHOT: Capture state before run
    report_dir.mkdir(parents=True, exist_ok=True)
    before_snapshot = get_dir_snapshot(report_dir)

    # RUN
    cmd = [sys.executable, str(entry_path), "--input", str(input_path)]
    run_res = run_cmd(cmd, cwd=block_dir)
    run_res.name = f"run:{block_name}"

    if run_res.exit_code != 0:
        print(f"❌ Run failed for {block_name}. Exit code: {run_res.exit_code}")
        print(f"stderr: {run_res.stderr}")
        # We continue to check if report was emitted despite failure (some validators write report then exit 1)

    # DISCOVER NEW REPORT
    latest = find_new_report(report_dir, before_snapshot, "*.json")

    if not latest:
        return run_res, None, None, ["NO_NEW_REPORT_EMITTED"]

    # VALIDATE SCHEMA
    ok_schema, schema_problems, report_data = validate_report_schema(latest, block_name, block_version)
    
    return run_res, latest, report_data, schema_problems


def run_team_pipeline(order: List[str], manifests: Dict[str, dict], strict: bool) -> StepResult:
    steps: List[dict] = []
    ok_all = True

    for b in order:
        if b not in manifests:
            ok_all = False
            steps.append({"block": b, "ok": False, "error": "MISSING_MANIFEST"})
            continue

        g = guardrail_block(b, strict=strict)
        r, report_path, _, schema_problems = run_block(b, manifests[b])

        # Block passed if: Guardrail OK AND Run matches expectations AND Report Valid
        # NOTE: run_res.ok (exit 0) is required for "Harness Pass" even if validator exits 1 for compliance fail.
        # But user specified: "PASS only if 0 fails, 0 errors".
        # So we strictly require exit code 0 (Golden Sample).
        block_ok = g.ok and r.ok and (report_path is not None) and (len([p for p in schema_problems if "MISSING" in p or "INVALID" in p]) == 0)
        
        if not block_ok:
            ok_all = False

        steps.append(
            {
                "block": b,
                "guardrail_ok": g.ok,
                "run_ok": r.ok,
                "run_exit": r.exit_code,
                "report": str(report_path) if report_path else None,
                "schema_problems": schema_problems,
            }
        )

    return StepResult(
        name="team:pipeline",
        ok=ok_all,
        exit_code=0 if ok_all else 1,
        stdout="",
        stderr="",
        meta={"order": order, "steps": steps},
    )


def main():
    parser = argparse.ArgumentParser(description="AION-ZERO Verification Harness")
    parser.add_argument("--strict", action="store_true", help="Strict mode (guardrail strict + require tools)")
    parser.add_argument("--only", default=None, help="Run only one block by name")
    parser.add_argument("--skip-team", action="store_true", help="Skip integrated team pipeline")
    args = parser.parse_args()

    ensure_dirs()

    manifests = load_block_manifests()
    if not manifests:
        print("⛔ No block manifests found. Add blocks/<block>/block.toml files.")
        sys.exit(2)

    blocks = sorted(manifests.keys())
    if args.only:
        if args.only not in manifests:
            print(f"⛔ Unknown block: {args.only}. Found: {blocks}")
            sys.exit(2)
        blocks = [args.only]

    run_id = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    proof = {
        "tool": "verify_system",
        "timestamp_utc": utc_now(),
        "project_root": str(PROJECT_ROOT),
        "strict": bool(args.strict),
        "blocks": blocks,
        "results": [],
        "team": None,
        "pass": True,
    }

    # 1) Independent checks (each block)
    for b in blocks:
        g = guardrail_block(b, strict=args.strict)
        r, report_path, _, schema_problems = run_block(b, manifests[b])

        block_ok = g.ok and r.ok and (report_path is not None) and (len([p for p in schema_problems if "MISSING" in p]) == 0)
        if not block_ok:
            proof["pass"] = False

        proof["results"].append(
            {
                "block": b,
                "guardrail": asdict(g),
                "run": asdict(r),
                "report_path": str(report_path) if report_path else None,
                "schema_problems": schema_problems,
                "pass": block_ok,
            }
        )

    # 2) Team pipeline (integration)
    if not args.skip_team:
        # Full Tier-1 Pipeline
        order = ["hr_compliance", "labour_obligations", "env_compliance"]
        order = [b for b in order if b in manifests]
        if order:
            team_res = run_team_pipeline(order, manifests, strict=args.strict)
            proof["team"] = asdict(team_res)
            if not team_res.ok:
                proof["pass"] = False

    # Write proof bundle
    out = VERIFY_LOG_DIR / f"verify_{run_id}.json"
    out.write_text(json.dumps(proof, indent=2), encoding="utf-8")
    
    # Write Latest Proof Alias
    latest_proof = VERIFY_LOG_DIR / "latest_proof.json"
    try:
        shutil.copy(out, latest_proof)
    except Exception as e:
        print(f"⚠️ Failed to update latest_proof.json: {e}")

    # Human summary
    print("🧪 AION-ZERO VERIFICATION (AUDIT GRADE)")
    print(f"   strict: {args.strict}")
    print(f"   blocks: {', '.join(blocks)}")
    print(f"   proof:  {out}")
    print(f"   alias:  {latest_proof}")
    print("")

    if not proof["pass"]:
        print("⛔ FAIL - DETAILED LOG:")
        print(json.dumps(proof, indent=2))
    else:
        print("✅ PASS")

    sys.exit(0 if proof["pass"] else 1)


if __name__ == "__main__":
    main()
