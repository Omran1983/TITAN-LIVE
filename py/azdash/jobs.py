from __future__ import annotations
from typing import Any, Dict, List, Optional
from dataclasses import asdict, dataclass
from uuid import uuid4
from datetime import datetime, timezone
import json, pathlib, threading

DATA_DIR = pathlib.Path(r"F:\AION-ZERO\py\azdash\data")
DATA_DIR.mkdir(parents=True, exist_ok=True)
DB_FILE = DATA_DIR / "jobs.jsonl"
_LOCK = threading.Lock()

def _now() -> str:
    return datetime.now(timezone.utc).isoformat()

@dataclass
class Job:
    id: str
    name: str
    params: Dict[str, Any]
    status: str
    created_at: str
    started_at: Optional[str] = None
    finished_at: Optional[str] = None
    result: Optional[Dict[str, Any]] = None
    error: Optional[str] = None

def _append(rec: dict) -> None:
    with _LOCK:
        with DB_FILE.open("a", encoding="utf-8") as f:
            f.write(json.dumps(rec, ensure_ascii=False) + "\n")

def new_job(name: str, params: Dict[str, Any]) -> Job:
    j = Job(id=str(uuid4()), name=name, params=params or {}, status="queued", created_at=_now())
    _append(asdict(j))
    return j

def update_job(j: Job) -> None:
    _append(asdict(j))

def list_jobs(limit: int = 100) -> List[dict]:
    rows: List[dict] = []
    if DB_FILE.exists():
        with DB_FILE.open("r", encoding="utf-8") as f:
            for line in f:
                try:
                    rows.append(json.loads(line))
                except Exception:
                    continue
    latest = {}
    for r in rows:
        latest[r["id"]] = r
    out = list(latest.values())
    out.sort(key=lambda r: r.get("created_at",""), reverse=True)
    return out[:limit]
