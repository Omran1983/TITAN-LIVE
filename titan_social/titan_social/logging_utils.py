import json
import time
from pathlib import Path
from typing import Dict, Any, List


class KillSwitchTripped(RuntimeError):
    pass


def ensure_dirs(out_dir: str, log_dir: str) -> None:
    Path(out_dir).mkdir(parents=True, exist_ok=True)
    Path(log_dir).mkdir(parents=True, exist_ok=True)


def log_event(log_dir: str, event: Dict[str, Any]) -> None:
    Path(log_dir).mkdir(parents=True, exist_ok=True)
    p = Path(log_dir) / "titan_social_events.jsonl"
    event = dict(event)
    event["ts"] = time.strftime("%Y-%m-%dT%H:%M:%S%z")
    with p.open("a", encoding="utf-8") as f:
        f.write(json.dumps(event, ensure_ascii=False) + "\n")


def _read_last_events(log_path: Path, n: int) -> List[dict]:
    if not log_path.exists():
        return []
    lines = log_path.read_text(encoding="utf-8").splitlines()
    tail = lines[-n:] if len(lines) >= n else lines
    out = []
    for ln in tail:
        try:
            out.append(json.loads(ln))
        except Exception:
            continue
    return out


def should_trip_kill_switch(*, log_dir: str, window: int, threshold: float) -> bool:
    log_path = Path(log_dir) / "titan_social_events.jsonl"
    events = _read_last_events(log_path, window)
    if len(events) < window:
        return False

    fails = sum(1 for e in events if e.get("status") == "FAIL")
    rate = fails / float(window)
    return rate > threshold
