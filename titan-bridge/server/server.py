import os
import json
import time
import uuid
from typing import Any, Dict, List, Optional, Literal

import httpx
import regex as re
import tomllib
from fastapi import FastAPI, Request, HTTPException, Depends
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, ConfigDict, validator


# -----------------------------
# Config
# -----------------------------
def load_toml(path: str) -> dict:
    with open(path, "rb") as f:
        return tomllib.load(f)

CFG = load_toml(os.environ.get("TITAN_CONFIG", "config/base.toml"))

MAX_BODY_BYTES = int(CFG["security"]["max_body_bytes"])
REQUIRE_BEARER = bool(CFG["security"]["require_bearer_token"])
CORS_ORIGINS = CFG["control_plane"].get("cors_allow_origins", ["*"])

CONTROL_PLANE_TOKEN = os.environ.get("CONTROL_PLANE_TOKEN", "")

SUPABASE_URL = os.environ.get(CFG["supabase"]["url_env"], "")
SUPABASE_SERVICE_KEY = os.environ.get(CFG["supabase"]["service_key_env"], "")
SUPABASE_SCHEMA = CFG["supabase"].get("schema", "public")

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    # Hard fail early; this is a control plane.
    raise RuntimeError("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars.")


# -----------------------------
# Supabase REST helpers
# -----------------------------
def supabase_headers() -> Dict[str, str]:
    return {
        "apikey": SUPABASE_SERVICE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Prefer": "return=representation",
    }

def supabase_table_url(table: str) -> str:
    # Supabase PostgREST endpoint
    # Example: https://xyz.supabase.co/rest/v1/az_commands
    return f"{SUPABASE_URL}/rest/v1/{table}"

async def sb_insert(table: str, payload: dict) -> dict:
    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.post(supabase_table_url(table), headers=supabase_headers(), json=payload)
        if r.status_code >= 300:
            raise HTTPException(status_code=500, detail={"error": "supabase_insert_failed", "body": r.text})
        data = r.json()
        return data[0] if isinstance(data, list) and data else payload

async def sb_select(table: str, query: str) -> list:
    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.get(f"{supabase_table_url(table)}?{query}", headers=supabase_headers())
        if r.status_code >= 300:
            raise HTTPException(status_code=500, detail={"error": "supabase_select_failed", "body": r.text})
        return r.json()

async def sb_patch(table: str, match_query: str, patch: dict) -> list:
    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.patch(f"{supabase_table_url(table)}?{match_query}", headers=supabase_headers(), json=patch)
        if r.status_code >= 300:
            raise HTTPException(status_code=500, detail={"error": "supabase_patch_failed", "body": r.text})
        return r.json()


# -----------------------------
# Auth + body limit
# -----------------------------
async def enforce_body_limit(request: Request):
    body = await request.body()
    if len(body) > MAX_BODY_BYTES:
        raise HTTPException(status_code=413, detail={"error": "payload_too_large", "max_bytes": MAX_BODY_BYTES})
    return body

def require_token(request: Request):
    if not REQUIRE_BEARER:
        return
    if not CONTROL_PLANE_TOKEN:
        raise HTTPException(status_code=500, detail={"error": "server_misconfigured_missing_CONTROL_PLANE_TOKEN"})
    auth = request.headers.get("authorization", "")
    if not auth.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail={"error": "missing_bearer_token"})
    token = auth.split(" ", 1)[1].strip()
    if token != CONTROL_PLANE_TOKEN:
        raise HTTPException(status_code=403, detail={"error": "invalid_token"})


# -----------------------------
# Schemas
# -----------------------------
AuthorityLevel = Literal["L0", "L1", "L2", "L3", "L4"]

class CommandCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    origin: str = Field(default="laptop", max_length=30)
    requested_by: str = Field(default="founder", max_length=80)

    title: str = Field(..., min_length=3, max_length=140)
    intent: str = Field(..., min_length=2, max_length=40)
    objective: str = Field(..., min_length=5, max_length=2000)

    targets: List[str] = Field(default_factory=list, max_items=12)
    constraints: List[str] = Field(default_factory=list, max_items=20)
    inputs: Dict[str, Any] = Field(default_factory=dict)

    definition_of_done: List[str] = Field(default_factory=list, max_items=15)
    notify: List[str] = Field(default_factory=list, max_items=10)

    authority_required: AuthorityLevel = Field(default="L1")
    priority: int = Field(default=2, ge=0, le=3)

class CommandApprove(BaseModel):
    model_config = ConfigDict(extra="forbid")
    approved_by: str = Field(..., min_length=2, max_length=80)

class AgentEvent(BaseModel):
    model_config = ConfigDict(extra="forbid")

    source: str = Field(..., min_length=2, max_length=80)  # agent_id
    command_id: Optional[str] = None
    severity: Literal["info","warn","critical"] = "info"
    event_type: str = Field(..., min_length=2, max_length=40)
    message: str = Field(..., min_length=1, max_length=2000)
    payload: Dict[str, Any] = Field(default_factory=dict)

class Briefing(BaseModel):
    model_config = ConfigDict(extra="forbid")
    ok: bool
    ts: str
    human_summary: str
    metrics: Dict[str, Any]
    blockers: List[Dict[str, Any]]
    recent_wins: List[Dict[str, Any]]


# -----------------------------
# App
# -----------------------------
app = FastAPI(title="TITAN Control Plane", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH"],
    allow_headers=["*"],
)

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(status_code=exc.status_code, content={"ok": False, "error": exc.detail})

@app.get("/v1/health")
async def health():
    return {"ok": True, "ts": time.strftime("%Y-%m-%dT%H:%M:%S%z"), "service": "control_plane"}

@app.post("/v1/commands")
async def create_command(request: Request, body=Depends(enforce_body_limit)):
    require_token(request)
    data = json.loads(body.decode("utf-8"))
    cmd = CommandCreate(**data)

    record = {
        "origin": cmd.origin,
        "requested_by": cmd.requested_by,
        "title": cmd.title,
        "intent": cmd.intent,
        "objective": cmd.objective,
        "targets": cmd.targets,
        "constraints": cmd.constraints,
        "inputs": cmd.inputs,
        "definition_of_done": cmd.definition_of_done,
        "notify": cmd.notify,
        "authority_required": cmd.authority_required,
        "priority": cmd.priority,
        "state": "QUEUED",
        "approved": False,
        "progress": 0,
    }
    inserted = await sb_insert("az_commands", record)

    await sb_insert("az_events", {
        "source": "control_plane",
        "command_id": inserted.get("command_id"),
        "severity": "info",
        "event_type": "state_change",
        "message": f"Command queued: {cmd.title}",
        "payload": {"state": "QUEUED"}
    })

    return {"ok": True, "command": inserted}

@app.get("/v1/commands/{command_id}")
async def get_command(command_id: str, request: Request):
    require_token(request)
    rows = await sb_select("az_commands", f"command_id=eq.{command_id}&select=*")
    if not rows:
        raise HTTPException(status_code=404, detail={"error": "not_found"})
    return {"ok": True, "command": rows[0]}

@app.patch("/v1/commands/{command_id}/approve")
async def approve_command(command_id: str, request: Request, body=Depends(enforce_body_limit)):
    require_token(request)
    data = json.loads(body.decode("utf-8"))
    approval = CommandApprove(**data)

    patched = await sb_patch("az_commands", f"command_id=eq.{command_id}", {
        "approved": True,
        "approved_by": approval.approved_by,
        "approved_at": "now()"
    })

    await sb_insert("az_events", {
        "source": "control_plane",
        "command_id": command_id,
        "severity": "info",
        "event_type": "approval",
        "message": f"Command approved by {approval.approved_by}",
        "payload": {"approved": True}
    })

    return {"ok": True, "command": patched[0] if patched else {"command_id": command_id, "approved": True}}

@app.get("/v1/health/agents")
async def agents_health(request: Request):
    require_token(request)
    rows = await sb_select("az_health_snapshots", "select=*")
    # Mark OFFLINE if last heartbeat too old (worker also does this)
    now_ts = time.time()
    result = []
    for r in rows:
        # r["ts"] is timestamptz; PostgREST returns ISO. We won’t parse here; client can.
        result.append(r)
    return {"ok": True, "agents": result}

@app.post("/v1/events/agent")
async def ingest_agent_event(request: Request, body=Depends(enforce_body_limit)):
    # Allow agents to post with token too (same token for v1)
    require_token(request)
    data = json.loads(body.decode("utf-8"))
    ev = AgentEvent(**data)

    inserted = await sb_insert("az_events", {
        "source": ev.source,
        "command_id": ev.command_id,
        "severity": ev.severity,
        "event_type": ev.event_type,
        "message": ev.message,
        "payload": ev.payload
    })

    # If heartbeat, upsert snapshot
    if ev.event_type == "heartbeat":
        # Upsert az_health_snapshots:
        # PostgREST upsert via Prefer header resolution=merge-duplicates requires unique constraint (agent_id PK exists)
        async with httpx.AsyncClient(timeout=15) as client:
            headers = supabase_headers()
            headers["Prefer"] = "resolution=merge-duplicates,return=representation"
            snap = {
                "agent_id": ev.source,
                "ts": "now()",
                "status": ev.payload.get("status", "IDLE"),
                "current_command_id": ev.payload.get("current_command_id"),
                "last_error": ev.payload.get("last_error"),
                "metrics": ev.payload.get("metrics", {})
            }
            r = await client.post(supabase_table_url("az_health_snapshots"), headers=headers, json=snap)
            if r.status_code >= 300:
                raise HTTPException(status_code=500, detail={"error": "snapshot_upsert_failed", "body": r.text})

        # Update command last heartbeat if provided
        if ev.command_id:
            await sb_patch("az_commands", f"command_id=eq.{ev.command_id}", {
                "last_heartbeat_at": "now()"
            })

    return {"ok": True, "event": inserted}

@app.get("/v1/briefing/daily")
async def daily_briefing(request: Request):
    require_token(request)

    # Recent commands (last 50)
    cmds = await sb_select("az_commands", "select=command_id,title,state,priority,progress,updated_at,created_at&order=updated_at.desc&limit=50")
    # Recent critical events
    evs = await sb_select("az_events", "severity=eq.critical&select=ts,source,command_id,event_type,message,payload&order=ts.desc&limit=25")

    done = [c for c in cmds if c["state"] == "DONE"]
    failed = [c for c in cmds if c["state"] == "FAILED"]
    running = [c for c in cmds if c["state"] in ("RUNNING","VERIFYING","CLAIMED")]
    queued = [c for c in cmds if c["state"] == "QUEUED"]
    needs_approval = [c for c in cmds if c["state"] == "NEEDS_APPROVAL"]

    human = (
        f"Today: {len(done)} done, {len(failed)} failed, {len(running)} running, "
        f"{len(queued)} queued, {len(needs_approval)} need approval. "
        f"Critical alerts: {len(evs)}."
    )

    briefing = Briefing(
        ok=True,
        ts=time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        human_summary=human,
        metrics={
            "done": len(done),
            "failed": len(failed),
            "running": len(running),
            "queued": len(queued),
            "needs_approval": len(needs_approval),
            "critical_alerts": len(evs),
        },
        blockers=[{"type": "critical_event", **e} for e in evs[:5]],
        recent_wins=[{"command_id": d["command_id"], "title": d["title"], "updated_at": d["updated_at"]} for d in done[:5]],
    )
    return briefing.model_dump()
