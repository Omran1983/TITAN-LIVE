import os
from pathlib import Path

def resolve_titan_root() -> Path:
    env_root = os.environ.get("TITAN_ROOT")
    if env_root:
        print(f"Using ENV TITAN_ROOT: {env_root}")
        return Path(env_root).resolve()
    print("Using Fallback TITAN_ROOT")
    return Path(__file__).resolve().parents[2]

root = resolve_titan_root()
print(f"TITAN_ROOT: {root}")
report_dir = root / "apps" / "inspector" / "reports"
print(f"REPORT_DIR: {report_dir}")
