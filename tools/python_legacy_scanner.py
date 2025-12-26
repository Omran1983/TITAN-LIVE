#!/usr/bin/env python3
"""
python_legacy_scanner.py

Scan a directory tree for legacy Python bootstrap patterns that can be abused
for supply-chain attacks (e.g., python-distribute.org + exec(urlopen(...))).

- Flags files named `bootstrap.py`
- Flags any file containing `python-distribute.org`
- Flags any file that uses exec() on data coming from urlopen()
- Writes a human-readable report to a .txt file
"""

from __future__ import annotations

import argparse
import datetime as _dt
from pathlib import Path
from typing import List, Tuple


# ------------------------- Configuration defaults ------------------------- #

DEFAULT_SCAN_ROOT = Path("F:/")  # You can change this default if you want


# ----------------------------- Scan logic --------------------------------- #

def find_suspicious_patterns(path: Path) -> List[str]:
    """
    Inspect a single file for suspicious legacy patterns.

    Returns a list of reason codes if the file looks suspicious.
    """
    reasons: List[str] = []

    # 1) Name-based heuristic: bootstrap.py
    if path.name.lower() == "bootstrap.py":
        reasons.append("BOOTSTRAP_FILE_NAME")

    # Only check text-like files (skip very large files quickly)
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except (OSError, UnicodeDecodeError):
        return reasons

    # 2) Hard-coded legacy domain python-distribute.org
    if "python-distribute.org" in text:
        reasons.append("PYTHON_DISTRIBUTE_DOMAIN")

    # 3) Very rough detection: exec() + urlopen in the same file
    #    This is similar to the vulnerable bootstrap behavior.
    if "exec(" in text and "urlopen" in text:
        reasons.append("EXEC_ON_URL_CONTENT")

    # 4) Optional: zc.buildout references
    if "zc.buildout" in text:
        reasons.append("ZC_BUILDOUT_REFERENCE")

    return reasons


def scan_tree(root: Path) -> List[Tuple[Path, List[str]]]:
    """
    Recursively scan `root` for suspicious Python files.

    Returns a list of (file_path, [reasons]) for all hits.
    """
    hits: List[Tuple[Path, List[str]]] = []

    for path in root.rglob("*.py"):
        try:
            reasons = find_suspicious_patterns(path)
        except Exception as e:
            # Don't let one weird file kill the scan
            print(f"[WARN] Error scanning {path}: {e}")
            continue

        if reasons:
            hits.append((path, reasons))

    return hits


# ----------------------------- Reporting ---------------------------------- #

def write_report(
    hits: List[Tuple[Path, List[str]]],
    root: Path,
    report_dir: Path | None = None,
) -> Path:
    """
    Write a report of findings to a timestamped .txt file.

    Returns the path to the created report.
    """
    if report_dir is None:
        report_dir = Path.cwd()

    report_dir.mkdir(parents=True, exist_ok=True)

    ts = _dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    report_path = report_dir / f"python_legacy_scan_report-{ts}.txt"

    lines: List[str] = []
    lines.append("Python Legacy Bootstrap / Supply-Chain Risk Scan")
    lines.append(f"Scan root: {root}")
    lines.append(f"Timestamp: {_dt.datetime.now().isoformat()}")
    lines.append("")
    lines.append("Legend / Reason codes:")
    lines.append("  BOOTSTRAP_FILE_NAME      = File named bootstrap.py (legacy buildout)")
    lines.append("  PYTHON_DISTRIBUTE_DOMAIN = References python-distribute.org")
    lines.append("  EXEC_ON_URL_CONTENT      = exec() + urlopen() in same file")
    lines.append("  ZC_BUILDOUT_REFERENCE    = References zc.buildout")
    lines.append("")
    lines.append("Findings:")
    lines.append("---------")

    if not hits:
        lines.append("No suspicious files found.")
    else:
        for path, reasons in hits:
            lines.append(f"- {path}")
            lines.append(f"    Reasons: {', '.join(reasons)}")

    report_path.write_text("\n".join(lines), encoding="utf-8")
    return report_path


# ------------------------------ CLI --------------------------------------- #

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Scan for legacy Python bootstrap patterns (python-distribute.org, exec(urlopen), bootstrap.py)."
    )
    parser.add_argument(
        "--root",
        type=str,
        default=str(DEFAULT_SCAN_ROOT),
        help=f"Root directory to scan (default: {DEFAULT_SCAN_ROOT})",
    )
    parser.add_argument(
        "--report-dir",
        type=str,
        default=".",
        help="Directory to write the scan report into (default: current directory).",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    root = Path(args.root).resolve()
    report_dir = Path(args.report_dir).resolve()

    if not root.exists():
        print(f"[ERROR] Root path does not exist: {root}")
        return

    print(f"[INFO] Starting legacy scan in: {root}")
    hits = scan_tree(root)

    print(f"[INFO] Scan complete. {len(hits)} suspicious file(s) found.")
    report_path = write_report(hits, root, report_dir=report_dir)
    print(f"[INFO] Report written to: {report_path}")


if __name__ == "__main__":
    main()
