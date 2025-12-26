import subprocess
from typing import Dict, Any


def run_powershell(command: str) -> Dict[str, Any]:
    \"\"\"Run a PowerShell command and capture output.\"\"\"
    try:
        completed = subprocess.run(
            ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", command],
            capture_output=True,
            text=True,
            check=False,
        )
        return {
            "ok": completed.returncode == 0,
            "code": completed.returncode,
            "stdout": completed.stdout,
            "stderr": completed.stderr,
        }
    except Exception as e:
        return {"ok": False, "code": -1, "stdout": "", "stderr": str(e)}


if __name__ == "__main__":
    # Simple smoke test
    result = run_powershell("Get-Date")
    print(result)
