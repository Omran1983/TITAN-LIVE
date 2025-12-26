#!/usr/bin/env python3
"""
TITAN Guardrail — AI Code Policy Enforcement
Status: ACTIVE

Usage:
  python core/quality/titan_guardrail.py --target blocks/hr_block
  python core/quality/titan_guardrail.py --target . --json out.json --strict

Exit codes:
  0 = PASS
  1 = FAIL (policy violations)
  2 = ERROR (guardrail itself failed)
"""

import argparse
import fnmatch
import hashlib
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Optional, Tuple


# -----------------------------
# Config (keep boring + explicit)
# -----------------------------
DEFAULT_MAX_LINES_PER_FILE = 300

DEFAULT_INCLUDE_GLOBS = ["**/*.py"]
DEFAULT_EXCLUDE_DIRS = {
    ".git", ".venv", "venv", "__pycache__", ".mypy_cache", ".ruff_cache",
    "node_modules", "dist", "build", ".pytest_cache"
}
DEFAULT_EXCLUDE_FILE_GLOBS = ["**/*.min.py"]

REQUIRED_TEST_FILE_GLOB = "test_*.py"
REQUIRED_TEST_DIR_NAMES = {"tests", "test"}

# A small "secret sniff" set. Not perfect, but catches 80% fast.
SECRET_PATTERNS = [
    # API keys / tokens (common)
    (re.compile(r"AKIA[0-9A-Z]{16}"), "AWS Access Key ID"),
    (re.compile(r"(?i)aws_secret_access_key\s*=\s*['\"][^'\"]+['\"]"), "AWS Secret Access Key"),
    (re.compile(r"(?i)api[_-]?key\s*=\s*['\"][^'\"]+['\"]"), "Generic API Key assignment"),
    (re.compile(r"(?i)secret\s*=\s*['\"][^'\"]+['\"]"), "Generic Secret assignment"),
    (re.compile(r"(?i)token\s*=\s*['\"][^'\"]+['\"]"), "Generic Token assignment"),
    (re.compile(r"eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9._-]{10,}\.[a-zA-Z0-9._-]{10,}"), "JWT-like token"),
    # Private key blocks
    (re.compile(r"-----BEGIN (?:RSA|EC|OPENSSH|PRIVATE) KEY-----"), "Private key material"),
]

# Allow big files via inline directive
ALLOW_LARGE_FILE_DIRECTIVE = re.compile(r"^\s*#\s*titan:\s*allow-large-file\s*$", re.IGNORECASE | re.MULTILINE)

# Count "logical" lines: skip blank and pure comments
COMMENT_LINE = re.compile(r"^\s*#")


@dataclass
class Finding:
    level: str  # "WARN" or "FAIL" or "ERROR"
    code: str
    message: str
    path: Optional[str] = None
    meta: Optional[dict] = None


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8", errors="ignore")).hexdigest()


class TitanGuardrail:
    def __init__(
        self,
        target_dir: str,
        max_lines_per_file: int = DEFAULT_MAX_LINES_PER_FILE,
        strict: bool = False,
        json_path: Optional[str] = None,
        allow_missing_tools: bool = True,
        ruff_args: Optional[List[str]] = None,
        bandit_args: Optional[List[str]] = None,
    ):
        self.target = Path(target_dir).resolve()
        self.max_lines_per_file = max_lines_per_file
        self.strict = strict
        self.json_path = Path(json_path).resolve() if json_path else None
        self.allow_missing_tools = allow_missing_tools

        self.ruff_args = ruff_args or ["check"]
        self.bandit_args = bandit_args or ["-r", "-ll"]  # medium+ only

        self.findings: List[Finding] = []
        self.scanned_files: List[Path] = []

        if not self.target.exists():
            raise FileNotFoundError(f"Target does not exist: {self.target}")

    # -----------------------------
    # File discovery
    # -----------------------------
    def _is_excluded(self, p: Path) -> bool:
        parts = {part.lower() for part in p.parts}
        if any(d.lower() in parts for d in DEFAULT_EXCLUDE_DIRS):
            return True
        # File globs excludes
        for g in DEFAULT_EXCLUDE_FILE_GLOBS:
            if fnmatch.fnmatch(str(p).replace("\\", "/"), g):
                return True
        return False

    def _collect_files(self) -> List[Path]:
        files: List[Path] = []
        for pattern in DEFAULT_INCLUDE_GLOBS:
            for p in self.target.glob(pattern):
                if p.is_file() and not self._is_excluded(p):
                    files.append(p)
        return sorted(files)

    # -----------------------------
    # Guardrail 1: Small Unit Rule (line sizes)
    # -----------------------------
    def check_file_sizes(self):
        for path in self.scanned_files:
            if path.suffix != ".py":
                continue
            try:
                content = path.read_text(encoding="utf-8", errors="ignore")
            except Exception as e:
                self.findings.append(Finding(
                    level="ERROR",
                    code="FILE_READ_ERROR",
                    message=f"Could not read file: {e}",
                    path=str(path),
                ))
                continue

            if ALLOW_LARGE_FILE_DIRECTIVE.search(content):
                continue

            logical_lines = 0
            for line in content.splitlines():
                if not line.strip():
                    continue
                if COMMENT_LINE.match(line):
                    continue
                logical_lines += 1

            if logical_lines > self.max_lines_per_file:
                self.findings.append(Finding(
                    level="WARN",
                    code="FILE_TOO_LARGE",
                    message=f"{path.name} has {logical_lines} logical lines (> {self.max_lines_per_file}). Consider splitting.",
                    path=str(path),
                    meta={"logical_lines": logical_lines, "max": self.max_lines_per_file},
                ))

    # -----------------------------
    # Guardrail 2: Test-First Mandate
    # -----------------------------
    def check_tests_exist(self):
        # Must have tests folder or at least one test_*.py under target
        test_files = list(self.target.rglob(REQUIRED_TEST_FILE_GLOB))
        test_dirs = [p for p in self.target.rglob("*") if p.is_dir() and p.name in REQUIRED_TEST_DIR_NAMES]

        # Exclude ignored dirs
        test_files = [p for p in test_files if not self._is_excluded(p)]
        test_dirs = [p for p in test_dirs if not self._is_excluded(p)]

        if not test_files and not test_dirs:
            self.findings.append(Finding(
                level="FAIL",
                code="NO_TESTS",
                message="No tests found: missing 'tests/' dir and no 'test_*.py' files.",
                path=str(self.target),
            ))
            return

        # Optional: sanity check tests reference target package name (weak heuristic but useful)
        # We do NOT fail on this; we warn.
        if self.target.is_dir():
            target_name = self.target.name
            referenced = False
            for tf in test_files[:25]:  # cap
                try:
                    t = tf.read_text(encoding="utf-8", errors="ignore")
                    if re.search(rf"\b{re.escape(target_name)}\b", t):
                        referenced = True
                        break
                except Exception:
                    continue
            if not referenced:
                self.findings.append(Finding(
                    level="WARN",
                    code="TESTS_MAY_NOT_TARGET_BLOCK",
                    message=f"Tests exist, but none appear to reference '{target_name}' (heuristic). Ensure tests cover the block.",
                    path=str(self.target),
                ))

    # -----------------------------
    # Guardrail 3: Security Scan Gate (Bandit)
    # -----------------------------
    def run_security_scan(self):
        cmd = ["bandit", *self.bandit_args, str(self.target)]
        try:
            subprocess.run(["bandit", "--version"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except FileNotFoundError:
            msg = "Bandit not installed. Run: pip install bandit"
            if self.allow_missing_tools:
                self.findings.append(Finding(level="WARN", code="BANDIT_MISSING", message=msg))
                return
            self.findings.append(Finding(level="FAIL", code="BANDIT_MISSING", message=msg))
            return
        except Exception as e:
            self.findings.append(Finding(level="ERROR", code="BANDIT_ERROR", message=f"Bandit version check failed: {e}"))
            return

        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            # Bandit returns non-zero when issues found OR on errors.
            if result.returncode != 0:
                out = (result.stdout or "")[:2000]
                err = (result.stderr or "")[:2000]
                self.findings.append(Finding(
                    level="FAIL",
                    code="BANDIT_ISSUES",
                    message="Bandit found security issues.",
                    path=str(self.target),
                    meta={"stdout": out, "stderr": err, "cmd": cmd},
                ))
        except Exception as e:
            self.findings.append(Finding(level="ERROR", code="BANDIT_EXEC_ERROR", message=str(e), path=str(self.target)))

    # -----------------------------
    # Guardrail 4: Ruff Lint Gate
    # -----------------------------
    def run_linter(self):
        # We default to ruff check; you can pass extra args via CLI
        cmd = ["ruff", *self.ruff_args, str(self.target)]
        try:
            subprocess.run(["ruff", "--version"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except FileNotFoundError:
            msg = "Ruff not installed. Run: pip install ruff"
            if self.allow_missing_tools:
                self.findings.append(Finding(level="WARN", code="RUFF_MISSING", message=msg))
                return
            self.findings.append(Finding(level="FAIL", code="RUFF_MISSING", message=msg))
            return
        except Exception as e:
            self.findings.append(Finding(level="ERROR", code="RUFF_ERROR", message=f"Ruff version check failed: {e}"))
            return

        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode != 0:
                out = (result.stdout or "")[:2000]
                err = (result.stderr or "")[:2000]
                self.findings.append(Finding(
                    level="FAIL",
                    code="RUFF_FAIL",
                    message="Ruff lint failed.",
                    path=str(self.target),
                    meta={"stdout": out, "stderr": err, "cmd": cmd},
                ))
        except Exception as e:
            self.findings.append(Finding(level="ERROR", code="RUFF_EXEC_ERROR", message=str(e), path=str(self.target)))

    # -----------------------------
    # Guardrail 5: No-Secrets Gate (fast heuristic)
    # -----------------------------
    def check_secrets(self):
        for path in self.scanned_files:
            if path.suffix not in {".py", ".env", ".txt", ".md", ".toml", ".json", ".yml", ".yaml"}:
                continue
            try:
                content = path.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                continue

            for rx, label in SECRET_PATTERNS:
                m = rx.search(content)
                if m:
                    # hash the matched substring to avoid printing secrets
                    snippet_hash = sha256_text(m.group(0))
                    self.findings.append(Finding(
                        level="FAIL",
                        code="POSSIBLE_SECRET",
                        message=f"Possible secret detected: {label}. Remove it and use env/secret manager.",
                        path=str(path),
                        meta={"match_hash": snippet_hash, "pattern": label},
                    ))

    # -----------------------------
    # Guardrail 6: Business context checklist (lightweight static checks)
    # -----------------------------
    def check_business_context_heuristics(self):
        # This is not a replacement for review. It catches obvious anti-patterns.
        float_money = re.compile(r"\bfloat\(")
        timezone_naive = re.compile(r"datetime\.now\(\)")
        shell_true = re.compile(r"shell\s*=\s*True")

        for path in self.scanned_files:
            if path.suffix != ".py":
                continue
            try:
                content = path.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                continue

            if float_money.search(content):
                # Ignore test/dummy files where float is fine
                if "dummy" not in path.name.lower() and "test" not in path.name.lower():
                    self.findings.append(Finding(
                        level="WARN",
                        code="MONEY_FLOAT_RISK",
                        message="Found float(...) usage. Prefer Decimal for currency.",
                        path=str(path),
                    ))
            if timezone_naive.search(content):
                self.findings.append(Finding(
                    level="WARN",
                    code="TIMEZONE_NAIVE_DATETIME",
                    message="Found datetime.now() usage. Prefer timezone-aware (UTC default).",
                    path=str(path),
                ))
            if shell_true.search(content):
                self.findings.append(Finding(
                    level="FAIL",
                    code="SHELL_TRUE_FORBIDDEN",
                    message="subprocess shell=True detected. Forbidden unless explicitly justified and isolated.",
                    path=str(path),
                ))

    # -----------------------------
    # Run
    # -----------------------------
    def execute(self) -> Tuple[bool, dict]:
        self.scanned_files = self._collect_files()

        report = {
            "tool": "titan_guardrail",
            "version": "1.1.0",
            "timestamp_utc": utc_now_iso(),
            "target": str(self.target),
            "strict": self.strict,
            "max_lines_per_file": self.max_lines_per_file,
            "scanned_file_count": len(self.scanned_files),
            "findings": [],
        }

        # Run checks
        self.check_file_sizes()
        self.check_tests_exist()
        self.run_linter()
        self.run_security_scan()
        self.check_secrets()
        self.check_business_context_heuristics()

        # Determine pass/fail
        fails = [f for f in self.findings if f.level in ("FAIL", "ERROR")]
        warns = [f for f in self.findings if f.level == "WARN"]

        # Strict mode converts WARN to FAIL
        if self.strict and warns:
            for w in warns:
                self.findings.append(Finding(
                    level="FAIL",
                    code="STRICT_WARN_AS_FAIL",
                    message=f"Strict mode: warning treated as fail -> {w.code}",
                    path=w.path,
                    meta=w.meta,
                ))
            fails = [f for f in self.findings if f.level in ("FAIL", "ERROR")]

        report["findings"] = [asdict(f) for f in self.findings]
        report["summary"] = {
            "pass": len(fails) == 0,
            "fail_count": len([f for f in self.findings if f.level == "FAIL"]),
            "error_count": len([f for f in self.findings if f.level == "ERROR"]),
            "warn_count": len([f for f in self.findings if f.level == "WARN"]),
        }

        return report["summary"]["pass"], report


def print_human_report(report: dict):
    s = report["summary"]
    print(f"🛡️ TITAN GUARDRAIL — target: {report['target']}")
    print(f"   scanned files: {report['scanned_file_count']}")
    print(f"   strict: {report['strict']}")
    print("")
    if s["pass"]:
        print("✅ GUARDRAIL PASSED.")
    else:
        print("⛔ GUARDRAIL FAILED.")
    print(f"   fails: {s['fail_count']} | errors: {s['error_count']} | warns: {s['warn_count']}")
    print("")

    for f in report["findings"]:
        level = f["level"]
        code = f["code"]
        path = f.get("path") or "-"
        msg = f["message"]
        print(f"[{level}] {code} :: {path}")
        print(f"  - {msg}")
        if f.get("meta"):
            # print small meta only; avoid dumping huge logs
            meta = f["meta"]
            safe_meta = {}
            for k in ("cmd", "pattern", "match_hash", "logical_lines", "max"):
                if k in meta:
                    safe_meta[k] = meta[k]
            if safe_meta:
                print(f"  - meta: {safe_meta}")
        print("")


def main():
    parser = argparse.ArgumentParser(description="TITAN AI Code Policy Guardrails")
    parser.add_argument("--target", required=True, help="Directory/block to scan")
    parser.add_argument("--max-lines", type=int, default=DEFAULT_MAX_LINES_PER_FILE, help="Max logical lines per file (warn)")
    parser.add_argument("--strict", action="store_true", help="Treat warnings as failures")
    parser.add_argument("--json", default=None, help="Write JSON report to this path")
    parser.add_argument("--require-tools", action="store_true", help="Fail if ruff/bandit missing")
    parser.add_argument("--ruff-args", default=None, help='Override ruff args, e.g. "check --fix"')
    parser.add_argument("--bandit-args", default=None, help='Override bandit args, e.g. "-r -ll -x tests"')

    args = parser.parse_args()

    try:
        ruff_args = args.ruff_args.split() if args.ruff_args else None
        bandit_args = args.bandit_args.split() if args.bandit_args else None

        guard = TitanGuardrail(
            target_dir=args.target,
            max_lines_per_file=args.max_lines,
            strict=args.strict,
            json_path=args.json,
            allow_missing_tools=not args.require_tools,
            ruff_args=ruff_args,
            bandit_args=bandit_args,
        )

        ok, report = guard.execute()

        # Write JSON if requested
        if args.json:
            Path(args.json).parent.mkdir(parents=True, exist_ok=True)
            Path(args.json).write_text(json.dumps(report, indent=2), encoding="utf-8")

        print_human_report(report)

        sys.exit(0 if ok else 1)

    except Exception as e:
        print("⛔ GUARDRAIL ERROR (tool failure):", e)
        sys.exit(2)


if __name__ == "__main__":
    main()
