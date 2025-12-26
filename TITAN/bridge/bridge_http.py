# TITAN/bridge/bridge_http.py
import os
import json
from pathlib import Path
from datetime import datetime
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

BRIDGE_DIR = Path(__file__).parent
TITAN_ROOT = BRIDGE_DIR.parent
INBOX = TITAN_ROOT / "io" / "inbox"
OUTBOX = TITAN_ROOT / "io" / "outbox"

INBOX.mkdir(parents=True, exist_ok=True)
OUTBOX.mkdir(parents=True, exist_ok=True)

app = FastAPI(title="TITAN Bridge v2", version="2.0")

class TaskEnvelope(BaseModel):
    version: str
    task_id: str
    request: dict
    limits: dict
    output: dict | None = None

def _ts():
    return datetime.now().strftime("%Y%m%d_%H%M%S")

@app.get("/v1/status")
def status():
    pending = sorted([p.name for p in INBOX.glob("*.json")])
    done = sorted([p.name for p in OUTBOX.glob("result_*.json")], reverse=True)[:10]
    return {
        "ok": True,
        "titan_root": str(TITAN_ROOT),
        "inbox_pending": pending,
        "outbox_recent": done
    }

@app.post("/v1/tasks")
def push_task(task: TaskEnvelope):
    stamp = _ts()
    out_name = f"task_{task.task_id}_{stamp}.json"
    out_path = INBOX / out_name
    out_path.write_text(task.model_dump_json(indent=2), encoding="utf-8")
    return {"ok": True, "path": str(out_path)}

@app.get("/v1/results/latest")
def latest_result():
    results = sorted(OUTBOX.glob("result_*.json"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not results:
        raise HTTPException(status_code=404, detail="No results yet.")
    p = results[0]
    return json.loads(p.read_text(encoding="utf-8"))

@app.get("/v1/results/{task_id}")
def result_by_task(task_id: str):
    matches = sorted(OUTBOX.glob(f"result_{task_id}*.json"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not matches:
        raise HTTPException(status_code=404, detail=f"No result for task_id={task_id}")
    return json.loads(matches[0].read_text(encoding="utf-8"))
