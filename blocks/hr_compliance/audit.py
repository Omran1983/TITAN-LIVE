"""
TITAN HR - Audit Logger
Append-only event log (jsonl). This is the system of record.
"""

import json
from pathlib import Path
from datetime import datetime, timezone
from typing import Any, Dict, Optional


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def log_event(
    *,
    data_root: str,
    event_type: str,
    client_cid: str,
    run_id: str,
    payload: Optional[Dict[str, Any]] = None,
    status: str = "OK",
) -> Dict[str, Any]:
    """
    Writes one line JSON event under:
      F:/AION-ZERO/data/clients/<CID>/audit/events.jsonl
    """
    root = Path(data_root)
    audit_dir = root / "clients" / client_cid / "audit"
    audit_dir.mkdir(parents=True, exist_ok=True)

    event = {
        "ts": _now_iso(),
        "event_type": event_type,
        "status": status,
        "client_cid": client_cid,
        "run_id": run_id,
        "payload": payload or {},
    }

    log_path = audit_dir / "events.jsonl"
    with open(log_path, "a", encoding="utf-8") as f:
        f.write(json.dumps(event, ensure_ascii=False) + "\n")

    return event


def read_recent_events(*, data_root: str, client_cid: str, limit: int = 200):
    root = Path(data_root)
    log_path = root / "clients" / client_cid / "audit" / "events.jsonl"
    if not log_path.exists():
        return []

    lines = log_path.read_text(encoding="utf-8").splitlines()
    tail = lines[-limit:] if len(lines) > limit else lines

    out = []
    for ln in reversed(tail):
        try:
            out.append(json.loads(ln))
        except Exception:
            continue
    return out
