import subprocess
from typing import List, Optional

def run_cmd(cmd: List[str], timeout: int = 60, cwd: Optional[str] = None) -> dict:
    """
    Runs a command and returns a structured result.
    Never raises; always returns {ok, code, out, err}.
    """
    try:
        p = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=cwd,
            shell=False
        )
        return {"ok": p.returncode == 0, "code": p.returncode, "out": p.stdout.strip(), "err": p.stderr.strip()}
    except Exception as e:
        return {"ok": False, "code": -1, "out": "", "err": str(e)}
