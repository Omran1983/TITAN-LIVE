from __future__ import annotations
import os, time, json
from typing import Dict, Any
from fastapi import FastAPI, Request
from .routers import agents as agents_router
from fastapi.responses import RedirectResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from loguru import logger

# AOGRL libs
from aogrl_ops_pack.logging_setup import init_logging
from aogrl_ops_pack.time_utils     import now_tz
from aogrl_ops_pack.http_client    import HttpClient
from aogrl_ops_pack.cache          import CacheManager

APP_TITLE = "AZ Local Ops"
BASE_DIR  = os.path.dirname(__file__)
UI_DIR    = os.path.join(BASE_DIR, "ui")

app = FastAPI(title=APP_TITLE)
app.include_router(agents_router.router, prefix='/api/agents', tags=['agents'])

@app.on_event("startup")
def _boot():
    os.makedirs(UI_DIR, exist_ok=True)
    init_logging()
    logger.info("AZ Local Ops UI started")

# serve /ui (index.html)
app.mount("/ui", StaticFiles(directory=UI_DIR, html=True), name="ui")

# redirect / -> /ui/
@app.get("/")
def _root():
    return RedirectResponse(url="/ui/")

# health
@app.get("/api/health")
def api_health() -> Dict[str, Any]:
    return {"ok": True, "when": str(now_tz()), "service": APP_TITLE}

# minimal command runner
def _run_cmd(cmd: str, args: list[str]) -> Dict[str, Any]:
    if cmd == "ping":
        c = HttpClient()
        try:
            r = c.get("https://api.binance.com/api/v3/ping", timeout=10.0)
            return {"ok": True, "status_code": r.status_code}
        finally:
            c.close()
    if cmd == "cache_put" and len(args) >= 2:
        k, v = args[0], " ".join(args[1:])
        CacheManager().set(k, v)
        return {"ok": True, "key": k}
    if cmd == "cache_get" and len(args) >= 1:
        k = args[0]
        val = CacheManager().get(k)
        return {"ok": True, "key": k, "value": val}
    if cmd == "status":
        return {"ok": True, "when": str(now_tz())}
    return {"ok": False, "error": "unknown_command_or_args", "cmd": cmd, "args": args}

@app.post("/api/run")
async def api_run(req: Request):
    body = await req.json()
    cmd  = (body.get("cmd") or "").strip()
    args = body.get("args") or []
    res  = _run_cmd(cmd, args)
    return JSONResponse(res)

# chat → tiny intent parser → calls _run_cmd
@app.post("/api/chat")
async def api_chat(req: Request):
    body = await req.json()
    msg  = (body.get("msg") or "").strip()
    low  = msg.lower()

    # intents
    if low in ("ping", "health", "status"):
        res = _run_cmd("ping" if low=="ping" else "status", [])
        return {"reply": f"OK: {json.dumps(res)}"}

    if low.startswith("cache put "):
        parts = msg.split()
        if len(parts) >= 4:
            # cache put <key> <value...>
            k = parts[2]; v = " ".join(parts[3:])
            res = _run_cmd("cache_put", [k, v])
            return {"reply": f"Stored: {json.dumps(res)}"}
        return {"reply": "Usage: cache put <key> <value>"}

    if low.startswith("cache get "):
        parts = msg.split()
        if len(parts) >= 3:
            k = parts[2]
            res = _run_cmd("cache_get", [k])
            return {"reply": f"Value: {json.dumps(res)}"}
        return {"reply": "Usage: cache get <key>"}

    # help
    help_text = (
        "Try: 'ping', 'status', 'cache put foo bar', 'cache get foo'. "
        "This is the local chat to AZ; public access comes later."
    )
    return {"reply": help_text}

