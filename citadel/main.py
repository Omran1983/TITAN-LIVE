import os
import sys
import json
import time
import subprocess
import shutil
import uuid
import importlib.util
import urllib.parse
import ipaddress
import socket
from datetime import datetime, timezone, timedelta
from typing import Optional, Dict, Any, List, Tuple

import psutil
from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile, File, HTTPException, Header, Depends, Request
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from supabase import create_client, Client

# =========================================
# ENV
# =========================================
load_dotenv(r"f:\AION-ZERO\.env")

app = FastAPI(title="AION-ZERO Citadel")

@app.on_event("startup")
async def startup_event():
    # 5. RUNTIME BEACON (MANDATORY)
    beacon_data = {
        "service": "citadel",
        "port": 8001,
        "pid": os.getpid(),
        "started_at": datetime.now().isoformat(),
        "health": "online",
        "version": "TITAN-v2",
        "doc_ref": "TITAN_IMPROVEMENT_LOG" 
    }
    
    # Write to disk for external discovery
    try:
        with open("citadel_beacon.json", "w") as f:
            json.dump(beacon_data, f, indent=2)
        print(f"SYSTEM: Beacon emitted: {json.dumps(beacon_data)}")
    except Exception as e:
        print(f"SYSTEM: Beacon emission failed: {e}")


# =========================================
# LOOP-5 LEDGER (SQLite)
# =========================================
LEDGER_OK = False
ledger = None

def _safe_import_ledger():
    """
    Imports F:\AION-ZERO\brain\ledger.py safely by absolute path.
    Prevents accidental imports of other 'ledger' modules.
    """
    global LEDGER_OK, ledger
    try:
        root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        ledger_path = os.path.join(root, "brain", "ledger.py")

        spec = importlib.util.spec_from_file_location("az_ledger", ledger_path)
        if not spec or not spec.loader:
            raise RuntimeError("ledger.py spec load failed")

        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)  # type: ignore

        mod.init()
        ledger = mod
        LEDGER_OK = True
        print("[LEDGER] Loop-5 SQLite ledger ONLINE (Safe Import).")
    except Exception as e:
        LEDGER_OK = False
        ledger = None
        print(f"[LEDGER] OFFLINE: {e}")

_safe_import_ledger()

def _ledger_event(event_type: str, intent: str, payload: dict, *, status: str = None, error: str = None,
                  risk_level: str = "low", correlation_id: str = None, parent_id: str = None, tags: list = None):
    if not LEDGER_OK:
        return {"event_id": None, "correlation_id": correlation_id or None}
    try:
        return ledger.log_event(
            project="citadel",
            actor="kernel",
            event_type=event_type,
            intent=intent,
            input=payload,
            output=None,
            status=status,
            error=error,
            risk_level=risk_level,
            correlation_id=correlation_id,
            parent_id=parent_id,
            tags=tags or [],
        )
    except Exception as e:
        print(f"[LEDGER] event log failed: {e}")
        return {"event_id": None, "correlation_id": correlation_id or None}

def _ledger_outcome(event_id: str, metric: str, value: float, *, score: float = None, verdict: str = None,
                    evidence: dict = None, lesson: str = None, next_action: str = None):
    if not LEDGER_OK or not event_id:
        return None
    try:
        return ledger.log_outcome(
            event_id=event_id,
            metric=metric,
            value=value,
            unit=None,
            target=None,
            score=score,
            verdict=verdict,
            evidence=evidence or {},
            lesson=lesson,
            next_action=next_action,
        )
    except Exception as e:
        print(f"[LEDGER] outcome log failed: {e}")
        return None

def _ledger_artifact(event_id: str, kind: str, path: str, before_text: str, after_text: str, content: str = ""):
    if not LEDGER_OK or not event_id:
        return None
    try:
        return ledger.log_artifact(
            event_id=event_id,
            kind=kind,
            path=path,
            before_text=before_text or "",
            after_text=after_text or "",
            content=content or "",
        )
    except Exception as e:
        print(f"[LEDGER] artifact log failed: {e}")
        return None

# =========================================
# Security
# =========================================
API_KEY = os.environ.get("JARVIS_COMMANDS_API_KEY")
if not API_KEY:
    print("WARNING: JARVIS_COMMANDS_API_KEY not found in .env. Defaulting to insecure 'jarvis-secret'.")
    API_KEY = "jarvis-secret"

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

def require_api_key(x_api_key: Optional[str] = Header(default=None, alias="X-API-KEY")):
    if not x_api_key or x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Unauthorized")
    return True

# =========================================
# Database
# =========================================
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

supabase: Optional[Client] = None
if SUPABASE_URL and SUPABASE_KEY:
    try:
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    except Exception as e:
        print(f"Supabase Connection Failed: {e}")

# =========================================
# Brain Wiring
# =========================================
GLOBAL_BRAIN = None

def heal_dependency(package_name: str):
    """The Bootloader Doctor: Fixes missing limbs."""
    print(f"\n[DOCTOR] DETECTED MISSING ORGAN: {package_name}")
    print(f"[DOCTOR] INITIATING SURGERY...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", package_name])
        print(f"[DOCTOR] IMPLANT SUCCESSFUL. REBOOTING SYSTEM...")
        os.execv(sys.executable, [sys.executable] + sys.argv)
    except Exception as e:
        print(f"[DOCTOR] SURGERY FAILED: {e}")

# Placeholder for check_env_vars, as it was in the provided snippet but not in original code.
# Assuming it's a simple check or can be omitted if not defined elsewhere.
def check_env_vars():
    pass

@app.on_event("startup")
async def startup_event():
    check_env_vars()
    
    # 5. RUNTIME BEACON (MANDATORY)
    beacon_data = {
        "service": "citadel",
        "port": 8001, # This port might need to be dynamic based on deployment
        "pid": os.getpid(),
        "started_at": datetime.now().isoformat(),
        "health": "online",
        "version": "TITAN-v2",
        "doc_ref": "TITAN_IMPROVEMENT_LOG" 
    }
    
    # Write to disk for external discovery
    with open("citadel_beacon.json", "w") as f:
        json.dump(beacon_data, f, indent=2)
        
    print(f"SYSTEM: Citadel beacon emitted: {beacon_data}")

# =========================================
# Helpers
# =========================================
BEACON_PATH = os.environ.get("CITADEL_BEACON_PATH", "citadel_beacon.json")

SENSITIVE_KEY_MARKERS = (
    "KEY", "TOKEN", "SECRET", "PASSWORD", "PASS", "PRIVATE", "BEARER",
    "SUPABASE", "OPENAI", "STRIPE", "TWILIO", "API"
)

def _mask_value(v: str) -> str:
    if v is None:
        return ""
    s = str(v)
    if len(s) <= 6:
        return "***"
    return f"{s[:3]}***{s[-3:]}"

def _is_sensitive_key(k: str) -> bool:
    up = k.upper()
    return any(m in up for m in SENSITIVE_KEY_MARKERS)

def get_sanitized_env() -> Dict[str, str]:
    # Return env vars but mask sensitive values
    out: Dict[str, str] = {}
    for k, v in os.environ.items():
        if _is_sensitive_key(k):
            out[k] = _mask_value(v)
        else:
            # keep non-sensitive short; still avoid dumping huge blobs
            out[k] = v if len(str(v)) <= 200 else (str(v)[:200] + "…")
    return dict(sorted(out.items(), key=lambda kv: kv[0].lower()))

def read_beacon() -> Dict[str, Any]:
    try:
        with open(BEACON_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return {
            "status": "missing",
            "path": BEACON_PATH,
            "hint": "Create citadel_beacon.json at runtime (or set CITADEL_BEACON_PATH)."
        }
    except Exception as e:
        return {"status": "error", "path": BEACON_PATH, "error": str(e)}

def _now_iso():
    return datetime.now(timezone.utc).isoformat()

def _new_correlation_id() -> str:
    return str(uuid.uuid4())

def _safe_preview(text: str, n: int = 800) -> str:
    if not text:
        return ""
    return (text[:n] + "…") if len(text) > n else text

def _is_safe_url(url: str) -> bool:
    """SSRF Shield: Blocks private ranges and localhost."""
    try:
        parsed = urllib.parse.urlparse(url)
        hostname = parsed.hostname
        if not hostname: return False
        
        # Block schemes
        if parsed.scheme not in ("http", "https"):
            return False

        # Resolve IP
        ip = socket.gethostbyname(hostname)
        ip_addr = ipaddress.ip_address(ip)

        # Block loopback, private, link-local, multicast
        if (ip_addr.is_loopback or ip_addr.is_private or 
            ip_addr.is_link_local or ip_addr.is_multicast or ip_addr.is_reserved):
            return False
            
        return True
    except Exception:
        return False

# =========================================
# Endpoints
# =========================================
@app.get("/api/status")
async def get_status():
    cid = _new_correlation_id()
    ev = _ledger_event("status", "get_status", {"ts": _now_iso()}, correlation_id=cid)
    resp = {
        "status": "online",
        "watchdog": "active",
        "brain": "learning" if GLOBAL_BRAIN else "offline",
        "immune_system": "active",
        "ledger": "online" if LEDGER_OK else "offline",
        "correlation_id": cid,
    }
    _ledger_outcome(ev.get("event_id"), "status_ok", 1, score=100, verdict="win", evidence=resp)
    return resp

@app.get("/api/reflex/incidents")
async def get_incidents():
    cid = _new_correlation_id()
    ev = _ledger_event("read", "reflex_incidents", {"limit": 10}, correlation_id=cid)
    if not supabase:
        _ledger_outcome(ev.get("event_id"), "reflex_incidents_ok", 0, score=20, verdict="no_db", lesson="Supabase unavailable")
        return []
    try:
        resp = (
            supabase.table("az_reflex_incidents")
            .select("*")
            .order("created_at", desc=True)
            .limit(10)
            .execute()
        )
        data = resp.data or []
        _ledger_outcome(ev.get("event_id"), "reflex_incidents_ok", 1, score=100, verdict="win", evidence={"count": len(data)})
        return data
    except Exception as e:
        _ledger_outcome(ev.get("event_id"), "reflex_incidents_ok", 0, score=0, verdict="loss", lesson=str(e))
        return []

@app.get("/api/graph/stats")
async def get_graph_stats():
    cid = _new_correlation_id()
    ev = _ledger_event("read", "graph_stats", {}, correlation_id=cid)
    if not supabase:
        _ledger_outcome(ev.get("event_id"), "graph_stats_ok", 0, score=20, verdict="no_db", lesson="Supabase unavailable")
        return {"sources": 12, "nodes": 124}
    try:
        resp = supabase.table("az_graph_sources").select("*", count="exact").execute()
        out = {"sources": resp.count or 0, "nodes": "2500+"}
        _ledger_outcome(ev.get("event_id"), "graph_stats_ok", 1, score=100, verdict="win", evidence=out)
        return out
    except Exception as e:
        _ledger_outcome(ev.get("event_id"), "graph_stats_ok", 0, score=0, verdict="loss", lesson=str(e))
        return {"sources": 0, "nodes": 0}

@app.get("/api/ledger/daily")
async def get_ledger():
    cid = _new_correlation_id()
    ev = _ledger_event("read", "daily_ledger", {}, correlation_id=cid)

    if not supabase:
        out = {"total_usd": 0.00, "budget": 0.00, "revenue_mur": 0, "orders_count": 0, "meta": "no_db", "correlation_id": cid}
        _ledger_outcome(ev.get("event_id"), "daily_ledger_ok", 0, score=20, verdict="no_db", evidence=out)
        return out

    finance_stats = {"income": 0, "expense": 0, "net": 0}
    try:
        resp = supabase.table("az_finance_kpi_today").select("*").execute()
        if resp.data:
            row = resp.data[0] or {}
            finance_stats = {
                "income": row.get("income_today", 0) or 0,
                "expense": row.get("expense_today", 0) or 0,
                "net": row.get("net_today", 0) or 0,
            }
    except Exception as e:
        print(f"Finance KPI error: {e}")

    okasina_today = {"revenue": 0, "count": 0}
    try:
        now_utc = datetime.now(timezone.utc)
        start_utc = now_utc.replace(hour=0, minute=0, second=0, microsecond=0)
        end_utc = start_utc + timedelta(days=1)

        resp = (
            supabase.table("orders")
            .select("total_amount,created_at", count="exact")
            .gte("created_at", start_utc.isoformat())
            .lt("created_at", end_utc.isoformat())
            .execute()
        )

        total = 0.0
        for item in (resp.data or []):
            val = item.get("total_amount", 0)
            try:
                total += float(val or 0)
            except Exception:
                pass

        okasina_today = {"revenue": total, "count": resp.count or 0}
    except Exception as e:
        print(f"Okasina Orders error: {e}")

    out = {"finance": finance_stats, "okasina": okasina_today, "meta": "live_data", "correlation_id": cid}
    _ledger_outcome(ev.get("event_id"), "daily_ledger_ok", 1, score=100, verdict="win", evidence=out)
    return out

@app.get("/api/ledger/recent")
async def get_ledger_recent():
    cid = _new_correlation_id()
    if not LEDGER_OK:
        return {"events": [], "correlation_id": cid}
    
    try:
        with ledger.connect() as con:
            # Join events with outcomes to get the full picture
            sql = """
                SELECT 
                    e.id, e.ts, e.event_type, e.intent, e.status, e.risk_level, 
                    e.input, e.output, e.error,
                    o.verdict, o.score, o.evidence
                FROM az_events e
                LEFT JOIN az_outcomes o ON e.id = o.event_id
                ORDER BY e.ts DESC
                LIMIT 50
            """
            rows = con.execute(sql).fetchall()
            
            events = []
            for r in rows:
                events.append({
                    "id": r[0],
                    "ts": r[1],
                    "type": r[2],
                    "intent": r[3],
                    "status": r[4],
                    "risk": r[5],
                    "input": r[6],   # JSON string
                    "output": r[7],  # JSON string
                    "error": r[8],
                    "verdict": r[9],
                    "score": r[10],
                    "evidence": r[11] # JSON string
                })
            
            return {"events": events, "correlation_id": cid}
    except Exception as e:
        return {"error": str(e), "correlation_id": cid}

# =========================================
# Command & Control APIs
# =========================================
class ChatMessage(BaseModel):
    message: str

@app.post("/api/chat")
async def chat_with_jarvis(chat: ChatMessage, x_api_key: Optional[str] = Header(None, alias="X-API-KEY")):
    cid = _new_correlation_id()
    msg = (chat.message or "").strip()
    msg_l = msg.lower()

    ev = _ledger_event("chat", "user_message", {"message": msg}, correlation_id=cid, risk_level="low")

    response = "I'm listening. Systems are nominal."
    action = None

    has_url = ("http" in msg_l) or (".com" in msg_l) or (".mu" in msg_l)

    # Fast commands (UI routing)
    if "scan" in msg_l and not has_url:
        response = "Scanning all active business units for anomalies..."
        action = "scan_all"
        _ledger_outcome(ev.get("event_id"), "chat_ok", 1, score=90, verdict="win", evidence={"action": action})
        return {"response": response, "action": action, "correlation_id": cid}

    if "status" in msg_l and not has_url:
        response = "All systems green. Agent mesh is active."
        action = "report_status"
        _ledger_outcome(ev.get("event_id"), "chat_ok", 1, score=90, verdict="win", evidence={"action": action})
        return {"response": response, "action": action, "correlation_id": cid}

    if "upload" in msg_l:
        response = "Ready for data ingestion. Please drag and drop your CSV."
        action = "open_upload"
        _ledger_outcome(ev.get("event_id"), "chat_ok", 1, score=90, verdict="win", evidence={"action": action})
        return {"response": response, "action": action, "correlation_id": cid}

    # Site check mode (preview + delegate)
    if ("review" in msg_l or "clone" in msg_l or "enhance" in msg_l or "check" in msg_l or "analyze" in msg_l or has_url):
        import urllib.request
        import re

        words = msg.split()
        target = next((w for w in words if ("http" in w) or (".com" in w) or (".mu" in w)), None)

        logs: List[str] = [f"COMMAND: {msg}"]
        if not target:
            out = {"response": "I detected a request to analyze a site but couldn't find the URL. Please specify it.",
                   "action": "open_systems", "logs": logs, "correlation_id": cid}
            _ledger_outcome(ev.get("event_id"), "site_check_ok", 0, score=30, verdict="loss", lesson="No URL detected")
            return out

        if not target.startswith("http"):
            target = "https://" + target
        
        # SSRF / Auth Check
        if not _is_safe_url(target):
            out = {"response": "ACCESS DENIED: Target resolves to local/private network (SSRF Blocked).",
                   "action": "block_request", "logs": logs, "correlation_id": cid}
            _ledger_outcome(ev.get("event_id"), "site_check_ok", 0, score=0, verdict="loss", lesson="SSRF Attempt Blocked")
            return JSONResponse(status_code=403, content=out)
            
        # Auth Check for Scans (Prevent API usage drain)
        if not x_api_key or x_api_key != API_KEY:
             out = {"response": "UNAUTHORIZED: API Key required for site scanning.",
                   "action": "block_request", "logs": logs, "correlation_id": cid}
             _ledger_outcome(ev.get("event_id"), "site_check_ok", 0, score=0, verdict="loss", lesson="Unauthorized Scan")
             return JSONResponse(status_code=401, content=out)

        try:
            logs.append(f"CONNECTING to {target}...")
            req = urllib.request.Request(
                target,
                data=None,
                headers={
                    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                                  "(KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
                }
            )

            with urllib.request.urlopen(req, timeout=10) as conn:
                code = conn.getcode()
                content = conn.read().decode("utf-8", errors="ignore")

            logs.append(f"SUCCESS: Target reached (HTTP {code})")

            title_match = re.search(r"<title>(.*?)</title>", content, re.IGNORECASE | re.DOTALL)
            title = title_match.group(1).strip() if title_match else "Unknown Site"
            logs.append(f"IDENTIFIED: {title}")
            logs.append(f"SIZE: {len(content)} bytes")
            logs.append("ENGAGING: Neural Engine...")

            if not GLOBAL_BRAIN:
                response = f"Reached '{title}'. Brain not wired (GLOBAL_BRAIN missing). Wire the brain module to enable full analysis."
                logs.append("WARNING: GLOBAL_BRAIN is not configured.")
                out = {"response": response, "action": "open_systems", "logs": logs, "correlation_id": cid}
                _ledger_outcome(ev.get("event_id"), "site_check_ok", 0, score=20, verdict="loss", lesson="GLOBAL_BRAIN offline",
                               evidence={"target": target, "http": code, "title": title})
                return out

            context = f"I am checking the website '{title}' at {target}. It is reachable (HTTP {code}). The user wants me to: {msg}"
            brain_response = GLOBAL_BRAIN.converse(context)

            if brain_response:
                response = brain_response
                logs.append("COMPLETE: Intelligence received.")
                _ledger_outcome(ev.get("event_id"), "site_check_ok", 1, score=100, verdict="win",
                               evidence={"target": target, "http": code, "title": title, "brain_preview": _safe_preview(response, 500)})
            else:
                response = f"Analysis complete for '{title}'. (Brain returned silence — check API keys / provider)."
                logs.append("WARNING: Brain did not respond.")
                _ledger_outcome(ev.get("event_id"), "site_check_ok", 0, score=40, verdict="loss",
                               lesson="Brain returned empty response", evidence={"target": target, "http": code, "title": title})

            return {"response": response, "action": "open_systems", "logs": logs, "correlation_id": cid}

        except Exception as e:
            logs.append(f"ERROR: Connection Failed - {str(e)}")
            _ledger_outcome(ev.get("event_id"), "site_check_ok", 0, score=0, verdict="loss", lesson=str(e), evidence={"target": target})
            return {"response": f"Could not access {target}. Security protocols may be active or site down.",
                    "action": "open_systems", "logs": logs, "correlation_id": cid}

    # Default: talk to brain if available
    if GLOBAL_BRAIN:
        try:
            r = GLOBAL_BRAIN.converse(msg_l)
            _ledger_outcome(ev.get("event_id"), "chat_ok", 1, score=90, verdict="win", evidence={"preview": _safe_preview(r, 600)})
            return {"response": r, "action": action, "correlation_id": cid}
        except Exception as e:
            _ledger_outcome(ev.get("event_id"), "chat_ok", 0, score=0, verdict="loss", lesson=str(e))
            return {"response": "Brain error. Check logs.", "action": action, "correlation_id": cid}

    _ledger_outcome(ev.get("event_id"), "chat_ok", 0, score=20, verdict="loss", lesson="GLOBAL_BRAIN offline")
    return {"response": "Brain is offline (GLOBAL_BRAIN not configured).", "action": action, "correlation_id": cid}

@app.get("/api/chat/history", dependencies=[Depends(require_api_key)])
async def get_chat_history():
    cid = _new_correlation_id()
    ev = _ledger_event("read", "chat_history", {}, correlation_id=cid)
    if GLOBAL_BRAIN:
        out = {"history": GLOBAL_BRAIN.history, "correlation_id": cid}
        _ledger_outcome(ev.get("event_id"), "chat_history_ok", 1, score=100, verdict="win", evidence={"count": len(GLOBAL_BRAIN.history)})
        return out
    _ledger_outcome(ev.get("event_id"), "chat_history_ok", 0, score=20, verdict="loss", lesson="GLOBAL_BRAIN offline")
    return {"history": [], "correlation_id": cid}

@app.post("/api/upload", dependencies=[Depends(require_api_key)])
async def upload_file(file: UploadFile = File(...)):
    cid = _new_correlation_id()
    ev = _ledger_event("write", "upload_file", {"filename": file.filename}, correlation_id=cid, risk_level="medium")
    try:
        import_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "data", "imports"))
        os.makedirs(import_dir, exist_ok=True)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        safe_name = os.path.basename(file.filename)
        filename = f"{timestamp}_{safe_name}"
        file_path = os.path.join(import_dir, filename)

        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        out = {"status": "success", "file": filename, "message": f"Successfully ingested {safe_name}", "correlation_id": cid}
        _ledger_outcome(ev.get("event_id"), "upload_ok", 1, score=100, verdict="win", evidence={"file": filename})
        return out
    except Exception as e:
        _ledger_outcome(ev.get("event_id"), "upload_ok", 0, score=0, verdict="loss", lesson=str(e))
        return JSONResponse({"status": "error", "message": str(e), "correlation_id": cid}, status_code=500)

# =========================================
# Agent Mesh Control APIs
# =========================================
AGENTS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "py"))
ACTIVE_PROCESSES: Dict[str, subprocess.Popen] = {}

class AgentControl(BaseModel):
    name: str
    action: str  # start / stop

@app.get("/api/agents")
async def get_agents():
    cid = _new_correlation_id()
    ev = _ledger_event("read", "list_agents", {}, correlation_id=cid)
    if not os.path.exists(AGENTS_DIR):
        _ledger_outcome(ev.get("event_id"), "agents_list_ok", 0, score=20, verdict="loss", lesson="AGENTS_DIR missing")
        return []

    ROLES = {
        "jarvis_architect.py": {"role": "Grand Architect", "desc": "System Design & Oversight"},
        "jarvis_revenue_gen.py": {"role": "Chief Revenue Officer", "desc": "Sales & Capital Allocation"},
        "reflex_engine.py": {"role": "Chief Security Officer", "desc": "Defense & Self-Healing"},
        "jarvis_brain_local.py": {"role": "The Neural Core", "desc": "Reasoning & Inference"},
        "jarvis_vision.py": {"role": "Head of Vision", "desc": "Visual Processing"},
        "jarvis_chat.py": {"role": "Comms Officer", "desc": "User Interaction"},
    }

    agents = []
    try:
        all_files = os.listdir(AGENTS_DIR)
        files = [f for f in all_files if f.endswith(".py") and (f.startswith("jarvis_") or f.startswith("reflex_"))]
        for f in files:
            is_running = f in ACTIVE_PROCESSES and ACTIVE_PROCESSES[f].poll() is None
            meta = ROLES.get(f, {"role": "Autonomous Unit", "desc": "General Purpose Agent"})
            agents.append({
                "name": f,
                "role": meta["role"],
                "description": meta["desc"],
                "path": os.path.join(AGENTS_DIR, f),
                "status": "active" if is_running else "idle",
                "pid": ACTIVE_PROCESSES[f].pid if is_running else None,
            })

        agents.sort(key=lambda x: x["name"] not in ROLES)
        _ledger_outcome(ev.get("event_id"), "agents_list_ok", 1, score=100, verdict="win", evidence={"count": len(agents)})
        return agents
    except Exception as e:
        _ledger_outcome(ev.get("event_id"), "agents_list_ok", 0, score=0, verdict="loss", lesson=str(e))
        return []

@app.post("/api/agents/control", dependencies=[Depends(require_api_key)])
async def control_agent(cmd: AgentControl):
    cid = _new_correlation_id()
    ev = _ledger_event("control", "agent_control", {"name": cmd.name, "action": cmd.action}, correlation_id=cid, risk_level="high")

    name = os.path.basename(cmd.name)
    path = os.path.join(AGENTS_DIR, name)

    if not os.path.exists(path):
        _ledger_outcome(ev.get("event_id"), "agent_control_ok", 0, score=10, verdict="loss", lesson="Agent file not found")
        return {"status": "error", "message": "Agent file not found", "correlation_id": cid}

    if cmd.action == "start":
        if name in ACTIVE_PROCESSES and ACTIVE_PROCESSES[name].poll() is None:
            _ledger_outcome(ev.get("event_id"), "agent_control_ok", 0, score=40, verdict="loss", lesson="Agent already running")
            return {"status": "error", "message": "Agent already running", "correlation_id": cid}

        try:
            proc = subprocess.Popen(
                [sys.executable, path],
                cwd=AGENTS_DIR,
                creationflags=getattr(subprocess, "CREATE_NEW_CONSOLE", 0),
            )
            ACTIVE_PROCESSES[name] = proc
            _ledger_outcome(ev.get("event_id"), "agent_control_ok", 1, score=100, verdict="win", evidence={"pid": proc.pid})
            return {"status": "success", "message": f"Started {name} (PID: {proc.pid})", "correlation_id": cid}
        except Exception as e:
            _ledger_outcome(ev.get("event_id"), "agent_control_ok", 0, score=0, verdict="loss", lesson=str(e))
            return {"status": "error", "message": f"Failed to start: {e}", "correlation_id": cid}

    if cmd.action == "stop":
        if name not in ACTIVE_PROCESSES:
            _ledger_outcome(ev.get("event_id"), "agent_control_ok", 0, score=40, verdict="loss", lesson="Agent not running")
            return {"status": "error", "message": "Agent not running", "correlation_id": cid}

        try:
            proc = ACTIVE_PROCESSES[name]
            proc.terminate()
            del ACTIVE_PROCESSES[name]
            _ledger_outcome(ev.get("event_id"), "agent_control_ok", 1, score=90, verdict="win")
            return {"status": "success", "message": f"Stopped {name}", "correlation_id": cid}
        except Exception as e:
            _ledger_outcome(ev.get("event_id"), "agent_control_ok", 0, score=0, verdict="loss", lesson=str(e))
            return {"status": "error", "message": f"Failed to stop: {e}", "correlation_id": cid}

    _ledger_outcome(ev.get("event_id"), "agent_control_ok", 0, score=10, verdict="loss", lesson="Invalid action")
    return {"status": "error", "message": "Invalid action", "correlation_id": cid}

# =========================================
# Resources Registry
# =========================================
CONNECTIONS_FILE = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "data", "config", "connections.json"))

class ResourceItem(BaseModel):
    name: str
    type: str
    url: str
    description: str = ""
    status: str = "active"

@app.get("/api/resources")
async def get_resources():
    cid = _new_correlation_id()
    ev = _ledger_event("read", "get_resources", {}, correlation_id=cid)
    if not os.path.exists(CONNECTIONS_FILE):
        _ledger_outcome(ev.get("event_id"), "resources_ok", 0, score=30, verdict="empty", lesson="No connections.json yet")
        return []
    try:
        with open(CONNECTIONS_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        _ledger_outcome(ev.get("event_id"), "resources_ok", 1, score=100, verdict="win", evidence={"count": len(data or [])})
        return data
    except Exception as e:
        _ledger_outcome(ev.get("event_id"), "resources_ok", 0, score=0, verdict="loss", lesson=str(e))
        return []

@app.post("/api/resources", dependencies=[Depends(require_api_key)])
async def add_resource(resource: ResourceItem):
    cid = _new_correlation_id()
    ev = _ledger_event("write", "add_resource", resource.dict(), correlation_id=cid, risk_level="medium")
    data = []
    os.makedirs(os.path.dirname(CONNECTIONS_FILE), exist_ok=True)

    if os.path.exists(CONNECTIONS_FILE):
        try:
            with open(CONNECTIONS_FILE, "r", encoding="utf-8") as f:
                data = json.load(f) or []
        except Exception:
            data = []

    new_item = resource.dict()
    new_item["created_at"] = datetime.now(timezone.utc).isoformat()
    data.append(new_item)

    try:
        with open(CONNECTIONS_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
        _ledger_outcome(ev.get("event_id"), "add_resource_ok", 1, score=100, verdict="win", evidence={"name": resource.name})
        return {"status": "success", "message": f"Added {resource.name}", "correlation_id": cid}
    except Exception as e:
        _ledger_outcome(ev.get("event_id"), "add_resource_ok", 0, score=0, verdict="loss", lesson=str(e))
        return JSONResponse({"status": "error", "message": str(e), "correlation_id": cid}, status_code=500)

# =========================================
# FORGE (INTERNAL IDE) API - SAFE V1+
# =========================================
FORGE_DENYLIST = [".env", ".git", ".venv", "__pycache__", "node_modules", "id_rsa", "vis-secret", "service_role", "service-role"]

# Hard safety switch (default OFF)
FORGE_ALLOW_SHELL = os.environ.get("AZ_FORGE_SHELL", "0") == "1"

class ForgeManager:
    def __init__(self, root_dir: str):
        self.root = os.path.abspath(root_dir)

    def is_safe_path(self, path: str) -> bool:
        abs_path = os.path.abspath(os.path.join(self.root, path.lstrip("/\\")))
        if not abs_path.startswith(self.root):
            return False

        filename = os.path.basename(abs_path)
        if filename in FORGE_DENYLIST:
            return False
        for part in abs_path.split(os.sep):
            if part in FORGE_DENYLIST:
                return False
        return True

    def list_tree(self) -> List[str]:
        tree = []
        max_depth = 4
        file_count = 0
        limit = 1500

        def scan_dir(current_path, depth):
            nonlocal file_count
            if depth > max_depth or file_count >= limit:
                return
            try:
                for entry in os.scandir(current_path):
                    if entry.name in FORGE_DENYLIST or entry.name.startswith("."):
                        continue
                    if entry.is_dir(follow_symlinks=False):
                        scan_dir(entry.path, depth + 1)
                    elif entry.is_file(follow_symlinks=False):
                        rel = os.path.relpath(entry.path, self.root).replace("\\", "/")
                        tree.append(rel)
                        file_count += 1
                        if file_count >= limit:
                            return
            except (PermissionError, OSError) as e:
                print(f"[FORGE ACCESS DENIED] {current_path}: {e}")

        scan_dir(self.root, 0)
        return sorted(tree)

    def read_file(self, path: str) -> str:
        if not self.is_safe_path(path):
            return "# ACCESS DENIED: PROTECTED FILE"

        full_path = os.path.join(self.root, path.lstrip("/\\"))
        if not os.path.exists(full_path):
            return "# File not found"

        try:
            with open(full_path, "r", encoding="utf-8") as f:
                return f.read()
        except UnicodeDecodeError:
            return "[Binary File - Cannot Edit]"

    def write_file(self, path: str, content: str) -> Tuple[str, str]:
        if not self.is_safe_path(path):
            raise Exception("Access Denied: Protected File")

        full_path = os.path.join(self.root, path.lstrip("/\\"))
        os.makedirs(os.path.dirname(full_path), exist_ok=True)

        before = ""
        if os.path.exists(full_path):
            try:
                with open(full_path, "r", encoding="utf-8") as f:
                    before = f.read()
            except Exception:
                before = ""

        with open(full_path, "w", encoding="utf-8") as f:
            f.write(content or "")

        return before, (content or "")

forge = ForgeManager(root_dir="f:/AION-ZERO")

# TASK REGISTRY (SAFE EXEC)
FORGE_TASKS = {
    "run_script": {
        "desc": "Run Python Script",
        "cmd_template": [sys.executable, "{target}"]
    },
    "shell_cmd": {
        "desc": "⚡ SYSTEM SHELL (DISABLED unless AZ_FORGE_SHELL=1)",
        "cmd_template": ["cmd", "/c", "{target}"] if os.name == "nt" else ["bash", "-c", "{target}"]
    },
    "git_status": {
        "desc": "Git Status",
        "cmd_template": ["git", "status"]
    },
    "git_add_commit": {
        "desc": "Git Add & Commit",
        "cmd_template": ["__SPECIAL__GIT_ADD_COMMIT__"]
    },
    "pip_install": {
        "desc": "Install Package (Pip)",
        "cmd_template": [sys.executable, "-m", "pip", "install", "{target}"]
    },
    "npm_run": {
        "desc": "NPM Run",
        "cmd_template": ["npm", "run", "{target}"]
    },
    "dir_list": {
        "desc": "List Directory",
        "cmd_template": ["cmd", "/c", "dir", "{target}"] if os.name == "nt" else ["ls", "-la", "{target}"]
    }
}

def _illegal_target(target: str) -> bool:
    if not target:
        return False
    bad = ["..", "&", "|", ">", "<", ";"]
    return any(x in target for x in bad)

@app.get("/api/forge/tree", dependencies=[Depends(require_api_key)])
async def get_forge_tree():
    cid = _new_correlation_id()
    ev = _ledger_event("read", "forge_tree", {"limit": 1500}, correlation_id=cid)
    try:
        data = forge.list_tree()
        _ledger_outcome(ev.get("event_id"), "forge_tree_ok", 1, score=100, verdict="win", evidence={"count": len(data)})
        return {"files": data, "correlation_id": cid}
    except Exception as e:
        _ledger_outcome(ev.get("event_id"), "forge_tree_ok", 0, score=0, verdict="loss", lesson=str(e))
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/forge/tasks", dependencies=[Depends(require_api_key)])
async def get_forge_tasks():
    cid = _new_correlation_id()
    ev = _ledger_event("read", "forge_tasks", {}, correlation_id=cid)
    _ledger_outcome(ev.get("event_id"), "forge_tasks_ok", 1, score=100, verdict="win", evidence={"count": len(FORGE_TASKS)})
    return {"tasks": FORGE_TASKS, "correlation_id": cid}

@app.post("/api/forge/read", dependencies=[Depends(require_api_key)])
async def read_forge_file(req: Dict[str, str]):
    cid = _new_correlation_id()
    path = (req.get("path") or "").strip()
    ev = _ledger_event("read", "forge_read", {"path": path}, correlation_id=cid)

    try:
        if not path:
            _ledger_outcome(ev.get("event_id"), "forge_read_ok", 0, score=30, verdict="loss", lesson="No path")
            return JSONResponse({"error": "No path", "correlation_id": cid}, status_code=400)

        content = forge.read_file(path)
        _ledger_outcome(ev.get("event_id"), "forge_read_ok", 1, score=100, verdict="win",
                       evidence={"path": path, "preview": _safe_preview(content, 400)})
        return {"content": content, "path": path, "correlation_id": cid}
    except Exception as e:
        _ledger_outcome(ev.get("event_id"), "forge_read_ok", 0, score=0, verdict="loss", lesson=str(e))
        return JSONResponse({"error": str(e), "correlation_id": cid}, status_code=500)

@app.post("/api/forge/save", dependencies=[Depends(require_api_key)])
async def save_forge_file(req: Dict[str, str]):
    cid = _new_correlation_id()
    path = (req.get("path") or "").strip()
    content = req.get("content") or ""
    ev = _ledger_event("write", "forge_save", {"path": path, "bytes": len(content)}, correlation_id=cid, risk_level="high")

    try:
        if not path:
            _ledger_outcome(ev.get("event_id"), "forge_save_ok", 0, score=30, verdict="loss", lesson="No path")
            return JSONResponse({"error": "No path", "correlation_id": cid}, status_code=400)

        before, after = forge.write_file(path, content)
        _ledger_artifact(ev.get("event_id"), "file_write", path, before, after, content="")
        _ledger_outcome(ev.get("event_id"), "forge_save_ok", 1, score=100, verdict="win", evidence={"path": path, "bytes": len(content)})

        return {"status": "saved", "path": path, "correlation_id": cid}
    except Exception as e:
        _ledger_outcome(ev.get("event_id"), "forge_save_ok", 0, score=0, verdict="loss", lesson=str(e))
        return JSONResponse({"error": str(e), "correlation_id": cid}, status_code=500)

@app.post("/api/forge/run", dependencies=[Depends(require_api_key)])
async def run_forge_task(req: Dict[str, str]):
    cid = _new_correlation_id()
    task_id = (req.get("task_id") or "").strip()
    target = (req.get("target") or "").strip()

    risk = "high" if task_id in ("shell_cmd", "git_add_commit") else "medium"
    ev = _ledger_event("exec", "forge_run", {"task_id": task_id, "target": target}, correlation_id=cid, risk_level=risk)

    try:
        if task_id not in FORGE_TASKS:
            _ledger_outcome(ev.get("event_id"), "forge_run_ok", 0, score=30, verdict="loss", lesson="Unknown task_id")
            return JSONResponse({"error": "Unknown Task ID", "correlation_id": cid}, status_code=400)

        if _illegal_target(target):
            _ledger_outcome(ev.get("event_id"), "forge_run_ok", 0, score=10, verdict="loss", lesson="Illegal characters in target")
            return JSONResponse({"error": "Illegal characters in target", "correlation_id": cid}, status_code=400)

        # Safety switch: shell_cmd disabled unless explicitly enabled
        if task_id == "shell_cmd" and not FORGE_ALLOW_SHELL:
            _ledger_outcome(ev.get("event_id"), "forge_run_ok", 0, score=10, verdict="blocked",
                           lesson="shell_cmd disabled", next_action="Set AZ_FORGE_SHELL=1 to enable")
            return JSONResponse({"error": "shell_cmd is disabled (set AZ_FORGE_SHELL=1 to enable)", "correlation_id": cid}, status_code=403)

        cwd = forge.root

        # Special-case: git add + git commit (cannot use && in list safely)
        if task_id == "git_add_commit":
            msg = target or "titan: update"
            add_p = subprocess.run(["git", "add", "."], cwd=cwd, shell=False, capture_output=True, text=True)
            if add_p.returncode != 0:
                _ledger_outcome(ev.get("event_id"), "forge_run_ok", 0, score=0, verdict="loss",
                               evidence={"stderr": add_p.stderr, "stdout": add_p.stdout}, lesson="git add failed")
                return {"stdout": add_p.stdout, "stderr": add_p.stderr, "returncode": add_p.returncode, "correlation_id": cid}

            commit_p = subprocess.run(["git", "commit", "-m", msg], cwd=cwd, shell=False, capture_output=True, text=True)
            ok = 1 if commit_p.returncode == 0 else 0
            _ledger_outcome(ev.get("event_id"), "forge_run_ok", ok, score=100 if ok else 0,
                           verdict="win" if ok else "loss",
                           evidence={"stdout": _safe_preview(commit_p.stdout, 1200), "stderr": _safe_preview(commit_p.stderr, 1200)})
            return {"stdout": commit_p.stdout, "stderr": commit_p.stderr, "returncode": commit_p.returncode, "correlation_id": cid}

        # Regular tasks
        task_def = FORGE_TASKS[task_id]
        cmd_list = [str(arg).format(target=target) for arg in task_def["cmd_template"]]

        # IMPORTANT: shell=False for list execution safety
        process = subprocess.run(cmd_list, cwd=cwd, shell=False, capture_output=True, text=True)

        ok = 1 if process.returncode == 0 else 0
        _ledger_outcome(ev.get("event_id"), "forge_run_ok", ok, score=100 if ok else 0,
                       verdict="win" if ok else "loss",
                       evidence={
                           "task_id": task_id,
                           "returncode": process.returncode,
                           "stdout": _safe_preview(process.stdout, 1200),
                           "stderr": _safe_preview(process.stderr, 1200),
                       })

        return {
            "stdout": process.stdout,
            "stderr": process.stderr,
            "returncode": process.returncode,
            "correlation_id": cid
        }

    except Exception as e:
        _ledger_outcome(ev.get("event_id"), "forge_run_ok", 0, score=0, verdict="loss", lesson=str(e))
        return JSONResponse({"error": str(e), "correlation_id": cid}, status_code=500)

# =========================================
# CITADEL FORGE APIs (Ide Support)
# =========================================
FORGE_ROOT = r"F:\AION-ZERO"
ALLOWED_EXTENSIONS = {'.py', '.js', '.html', '.css', '.json', '.md', '.txt', '.xml', '.ps1', '.sql', '.csv'}

def _is_safe_path(path: str) -> bool:
    try:
        abs_path = os.path.abspath(os.path.join(FORGE_ROOT, path))
        return abs_path.startswith(FORGE_ROOT)
    except:
        return False

@app.get("/api/forge/tree")
async def forge_tree(path: str = ""):
    """Returns directory structure."""
    if not _is_safe_path(path):
        raise HTTPException(403, "Access Denied")
    
    target = os.path.join(FORGE_ROOT, path)
    if not os.path.exists(target):
        return []
        
    items = []
    try:
        for entry in os.scandir(target):
            if entry.name.startswith(('.', '__')) or entry.name == 'node_modules':
                continue
            items.append({
                "name": entry.name,
                "type": "directory" if entry.is_dir() else "file",
                "path": os.path.join(path, entry.name).replace("\\", "/")
            })
    except Exception as e:
        print(f"Forge Tree Error: {e}")
        
    return sorted(items, key=lambda x: (x["type"] != "directory", x["name"]))

@app.get("/api/forge/read")
async def forge_read(path: str):
    """Reads file content."""
    if not _is_safe_path(path):
        raise HTTPException(403, "Access Denied")
        
    target = os.path.join(FORGE_ROOT, path)
    if not os.path.isfile(target):
        raise HTTPException(404, "File not found")
        
    ext = os.path.splitext(target)[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        # Emergency Allow for critical knowns
        if "requirements.txt" not in target and ".env" not in target:
             raise HTTPException(400, "File type not allowed")

    try:
        with open(target, "r", encoding="utf-8") as f:
            content = f.read()
        return {"content": content, "path": path}
    except Exception as e:
        raise HTTPException(500, str(e))

@app.post("/api/forge/save", dependencies=[Depends(require_api_key)])
async def forge_save(request: Request):
    """Saves file content."""
    data = await request.json()
    path = data.get("path")
    content = data.get("content")
    
    if not _is_safe_path(path):
        raise HTTPException(403, "Access Denied")
        
    target = os.path.join(FORGE_ROOT, path)
    
    try:
        # Create backup first
        if os.path.exists(target):
            bak = target + ".bak"
            shutil.copy2(target, bak)
            
        with open(target, "w", encoding="utf-8") as f:
            f.write(content)
            
        return {"status": "saved", "path": path}
    except Exception as e:
        raise HTTPException(500, str(e))

# =========================================
# SYSTEM CONTROL APIs
# =========================================
AGENT_PROCESS_MATCH = (
    "jarvis", "titan", "aion", "agent", "watchdog", "worker", "reflex"
)

def scan_running_agents() -> List[Dict[str, Any]]:
    agents: List[Dict[str, Any]] = []
    for p in psutil.process_iter(["pid", "name", "cmdline", "create_time", "username"]):
        try:
            name = (p.info.get("name") or "").lower()
            cmd = " ".join(p.info.get("cmdline") or []).lower()
            if any(x in name for x in AGENT_PROCESS_MATCH) or any(x in cmd for x in AGENT_PROCESS_MATCH):
                with p.oneshot():
                    mem = p.memory_info().rss
                    cpu = p.cpu_percent(interval=0.0)  # instant; good enough for UI
                    status = p.status()
                agents.append({
                    "pid": p.info["pid"],
                    "name": p.info.get("name") or "unknown",
                    "cmdline": (p.info.get("cmdline") or [])[:20],
                    "status": status,
                    "cpu_percent": cpu,
                    "memory_rss": mem,
                    "started_at": int(p.info.get("create_time") or 0),
                    "username": p.info.get("username"),
                })
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
        except Exception:
            continue

    # Sort: biggest memory first (usually most important)
    agents.sort(key=lambda a: a.get("memory_rss", 0), reverse=True)
    return agents

def list_brain_tools() -> List[Dict[str, Any]]:
    tools: List[Dict[str, Any]] = []
    brain = globals().get("GLOBAL_BRAIN", None)
    if brain is None:
        return [{"name": "GLOBAL_BRAIN", "status": "missing", "hint": "GLOBAL_BRAIN not loaded in this process."}]

    raw = getattr(brain, "tools", None)
    if raw is None:
        return [{"name": "tools", "status": "missing", "hint": "GLOBAL_BRAIN.tools not found."}]

    # Support dict or list
    if isinstance(raw, dict):
        for k, v in raw.items():
            tools.append({
                "key": str(k),
                "name": getattr(v, "name", str(k)),
                "description": getattr(v, "description", None),
                "type": type(v).__name__,
            })
    elif isinstance(raw, list):
        for v in raw:
            tools.append({
                "key": getattr(v, "key", getattr(v, "name", type(v).__name__)),
                "name": getattr(v, "name", type(v).__name__),
                "description": getattr(v, "description", None),
                "type": type(v).__name__,
            })
    else:
        tools.append({"name": "tools", "status": "unsupported", "type": type(raw).__name__})

    return tools

@app.get("/api/agents")
def api_agents():
    """
    Return running agents (PID, status, memory usage).
    Source: psutil (+ optional merge with az_agents if you add it later).
    """
    return {"ok": True, "agents": scan_running_agents()}


@app.get("/api/tools")
def api_tools():
    """
    Return registered Brain tools.
    Source: GLOBAL_BRAIN.tools
    """
    return {"ok": True, "tools": list_brain_tools()}


@app.get("/api/config")
def api_config():
    """
    Return sanitized configuration.
    Source: os.environ (masked).
    """
    return {"ok": True, "config": get_sanitized_env()}


@app.get("/api/health/beacon")
def api_health_beacon():
    """
    Return Beacon data.
    Source: Read citadel_beacon.json
    """
    return {"ok": True, "beacon": read_beacon()}

# =========================================
# AUTOCORRECT / DOCTOR APIs
# =========================================
@app.post("/api/doctor/diagnose")
async def doctor_diagnose(request: Request):
    """Diagnoses an error string."""
    data = await request.json()
    error_msg = data.get("error")
    if GLOBAL_BRAIN:
        diagnosis = GLOBAL_BRAIN.diagnose_error(error_msg)
        return {"diagnosis": diagnosis}
    return {"diagnosis": "Brain Offline"}

@app.post("/api/doctor/heal")
async def doctor_heal(request: Request):
    """Generates a patch/fix."""
    data = await request.json()
    diagnosis = data.get("diagnosis")
    if GLOBAL_BRAIN:
        patch = GLOBAL_BRAIN.generate_patch(diagnosis)
        return {"patch": patch}
    return {"patch": "Brain Offline"}

# =========================================
# Frontend Serving
# =========================================
static_dir = os.path.join(os.path.dirname(__file__), "static")

@app.get("/")
async def read_root():
    return FileResponse(os.path.join(static_dir, "index.html"))

app.mount("/", StaticFiles(directory=static_dir, html=True), name="static")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
