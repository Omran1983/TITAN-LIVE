# tools/powershell.py
import subprocess, os, pathlib

ALLOWED = [r"C:\Dev", r"C:\Users\ICL  ZAMBIA\Desktop\Binance Automation"]

def _norm(p: str) -> str:
    return pathlib.Path(p).resolve().as_posix().lower()

NORM_ALLOW = [_norm(p) for p in ALLOWED]

def _is_allowed(cwd: str) -> bool:
    try:
        cp = _norm(cwd)
        return any(cp.startswith(a) for a in NORM_ALLOW)
    except Exception:
        return False

def _which(cmd: str):
    from shutil import which
    return which(cmd)

def run(command: str, cwd: str = r"C:\Dev") -> dict:
    if not _is_allowed(cwd):
        return {"ok": False, "stdout": "", "stderr": f"cwd '{cwd}' not in allowlist", "rc": 99}

    exe = os.environ.get("POWERSHELL_EXE", "pwsh")
    if not _which(exe):
        exe = "powershell.exe"

    try:
        proc = subprocess.run(
            [exe, "-NoLogo", "-NoProfile", "-Command", command],
            cwd=cwd, capture_output=True, text=True, timeout=180
        )
        return {
            "ok": proc.returncode == 0,
            "stdout": (proc.stdout or "").strip(),
            "stderr": (proc.stderr or "").strip(),
            "rc": proc.returncode
        }
    except Exception as e:
        return {"ok": False, "stdout": "", "stderr": str(e), "rc": 98}
