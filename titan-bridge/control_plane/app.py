import os, re, time
from typing import Any, Dict, Optional, List

import httpx
from fastapi import FastAPI, Request, HTTPException

app = FastAPI(title="TITAN Bridge Control Plane", version="3.1.0")

SUPABASE_URL = os.environ["SUPABASE_URL"].strip()
SUPABASE_SERVICE_ROLE_KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"].strip()

TELEGRAM_BOT_TOKEN = os.environ["TELEGRAM_BOT_TOKEN"].strip()
TELEGRAM_WEBHOOK_SECRET = os.environ.get("TELEGRAM_WEBHOOK_SECRET", "").strip()  # optional

# Security: Chat Allowlist (optional but recommended)
# If set, only these chat IDs can trigger commands.
ALLOWED_CHAT_IDS = [
    x.strip() for x in os.environ.get("ALLOWED_CHAT_IDS", "").split(",") if x.strip()
]

# Agent offline threshold seconds (for status)
AGENT_OFFLINE_AFTER_SECONDS = int(os.environ.get("AGENT_OFFLINE_AFTER_SECONDS", "120"))

# Built-in project aliases (works even without az_projects)
PROJECT_ALIASES = {
    "smoke": "titan_smoke",
    "inspect": "titan_inspect",
    "inspector": "titan_inspect",
    "deploy": "titan_deploy_local",
    "citadel": "titan_deploy_local",
    "titan_smoke": "titan_smoke",
    "titan_inspect": "titan_inspect",
    "titan_deploy_local": "titan_deploy_local",
    "grants": "grant_refresh",
    "grant_refresh": "grant_refresh",
}

# ----------------- Supabase helpers -----------------
def sb_headers():
    return {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Prefer": "return=representation",
    }

def sb_url(table: str) -> str:
    return f"{SUPABASE_URL}/rest/v1/{table}"

async def sb_insert(table: str, payload: dict) -> dict:
    async with httpx.AsyncClient(timeout=20) as client:
        r = await client.post(sb_url(table), headers=sb_headers(), json=payload)
        if r.status_code >= 300:
            raise HTTPException(500, {"error": "supabase_insert_failed", "detail": r.text})
        data = r.json()
        return data[0] if isinstance(data, list) and data else payload

async def sb_select(table: str, query: str) -> list:
    async with httpx.AsyncClient(timeout=20) as client:
        r = await client.get(f"{sb_url(table)}?{query}", headers=sb_headers())
        if r.status_code >= 300:
            raise HTTPException(500, {"error": "supabase_select_failed", "detail": r.text})
        return r.json()

async def sb_patch(table: str, query: str, patch: dict) -> list:
    async with httpx.AsyncClient(timeout=20) as client:
        r = await client.patch(f"{sb_url(table)}?{query}", headers=sb_headers(), json=patch)
        if r.status_code >= 300:
            raise HTTPException(500, {"error": "supabase_patch_failed", "detail": r.text})
        return r.json()

async def emit_event(source: str, command_id: Optional[str], severity: str, event_type: str, message: str, payload: dict):
    await sb_insert("az_events", {
        "source": source,
        "command_id": command_id,
        "severity": severity,
        "event_type": event_type,
        "message": message,
        "payload": payload
    })

# ----------------- Telegram helpers -----------------
async def tg_send(chat_id: str, text: str):
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    async with httpx.AsyncClient(timeout=20) as client:
        r = await client.post(url, json={"chat_id": chat_id, "text": text[:3900]})
        
        # audit (best effort)
        # Fix: use now_iso() or allow DB default (omitting is safest if DB has default now())
        # We'll use now_iso() to be explicit and avoid SQL function literal issues.
        audit_payload = {
            "chat_id": str(chat_id),
            "message": text[:3900],
            "sent": r.status_code < 300,
            "error": None if r.status_code < 300 else r.text[:1000]
        }
        if r.status_code < 300:
            audit_payload["sent_at"] = now_iso()
            
        try:
            await sb_insert("az_telegram_outbox", audit_payload)
        except Exception:
            pass

def now_iso():
    return time.strftime("%Y-%m-%dT%H:%M:%S%z")

# ----------------- Built-in commands -----------------
def parse_command(text: str) -> Dict[str, Any]:
    t = (text or "").strip()
    lower = t.lower()

    if lower in ("help", "/help", "commands"):
        return {"builtin": "help"}
    if lower in ("status", "/status"):
        return {"builtin": "status"}
    if lower in ("last", "/last"):
        return {"builtin": "last"}
    if lower in ("projects", "/projects"):
        return {"builtin": "projects"}
    if lower in ("errors", "/errors"):
        return {"builtin": "errors"}

    m_tail = re.match(r"^(tail|/tail)\s+([0-9a-fA-F\-]{8,})", t)
    if m_tail:
        return {"builtin": "tail", "id": m_tail.group(2)}

    m_cancel = re.match(r"^(cancel|/cancel)\s+([0-9a-fA-F\-]{8,})", t)
    if m_cancel:
        return {"builtin": "cancel", "id": m_cancel.group(2)}

    # priority tags
    priority = 1
    if " p0" in (" " + lower) or "urgent" in lower:
        priority = 0
    elif " p2" in (" " + lower):
        priority = 2
    elif " p3" in (" " + lower):
        priority = 3

    # v2 wildfire
    if lower.startswith("/v2 ") or lower.startswith("/wildfire "):
        parts = t.split(" ", 2)
        action = parts[1].lower() if len(parts) > 1 else "help"
        args = parts[2] if len(parts) > 2 else ""
        inputs = {"raw": args, "text": args}
        if args.startswith("http"):
            inputs["url"] = args
            
        return {
            "intent": f"v2.{action}",
            "title": f"🔥 {action.upper()}",
            "objective": t,
            "inputs": inputs,
            "priority": priority
        }

    # run <project>
    if lower.startswith("run ") or lower.startswith("/run "):
        key = t.split(" ", 1)[1].strip().lower()
        project_id = PROJECT_ALIASES.get(key, key)
        return {
            "intent": "project.run",
            "title": f"RUN {project_id}",
            "objective": t,
            "inputs": {"project_id": project_id},
            "priority": priority
        }

    # shell commands
    if lower.startswith("ps:"):
        return {"intent": "shell.powershell", "title": "PowerShell", "objective": t, "inputs": {"command": t.split(":", 1)[1].strip()}, "priority": priority}
    if lower.startswith("cmd:"):
        return {"intent": "shell.cmd", "title": "CMD", "objective": t, "inputs": {"command": t.split(":", 1)[1].strip()}, "priority": priority}
    if lower.startswith("py:"):
        return {"intent": "shell.python", "title": "Python", "objective": t, "inputs": {"command": t.split(":", 1)[1].strip()}, "priority": priority}
    if lower.startswith("node:"):
        return {"intent": "shell.node", "title": "Node", "objective": t, "inputs": {"command": t.split(":", 1)[1].strip()}, "priority": priority}
    if lower.startswith("docker:"):
        return {"intent": "shell.docker", "title": "Docker", "objective": t, "inputs": {"command": t.split(":", 1)[1].strip()}, "priority": priority}

    # default fall-through
    return {
        "intent": "project.run",
        "title": "RUN titan_smoke (default)",
        "objective": t,
        "inputs": {"project_id": "titan_smoke", "raw": t},
        "priority": priority
    }

async def builtin_help(chat_id: str):
    msg = (
        "TITAN Bridge v3.1 — Commands\n\n"
        "Execution:\n"
        "  run smoke | run inspect | run deploy\n"
        "  ps: <powershell>\n"
        "  cmd: <cmd>\n"
        "  py: <python -c>\n"
        "  node: <node -e>\n"
        "  docker: <docker args>\n\n"
        "Ops:\n"
        "  status\n"
        "  last\n"
        "  tail <command_id>\n"
        "  errors\n"
        "  projects\n"
        "  cancel <command_id>\n"
    )
    await tg_send(chat_id, msg)

async def builtin_projects(chat_id: str):
    # If az_projects exists, prefer it; otherwise show built-in aliases
    try:
        rows = await sb_select("az_projects", "enabled=eq.true&select=project_id,display_name,description&order=project_id.asc")
        if rows:
            msg = "Projects:\n"
            for r in rows[:30]:
                msg += f"- {r['project_id']}: {r.get('display_name','')}\n"
            msg += "\nAliases: smoke, inspect, deploy, citadel"
            await tg_send(chat_id, msg)
            return
    except Exception:
        pass

    msg = (
        "Projects (built-in):\n"
        "- titan_smoke (alias: smoke)\n"
        "- titan_inspect (alias: inspect / inspector)\n"
        "- titan_deploy_local (alias: deploy / citadel)\n"
    )
    await tg_send(chat_id, msg)

async def builtin_status(chat_id: str):
    cmds = await sb_select(
        "az_commands",
        "select=command_id,title,state,priority,progress,updated_at&order=updated_at.desc&limit=50"
    )
    agents = await sb_select("az_health_snapshots", "select=agent_id,ts,status,current_command_id,last_error,metrics")

    done = sum(1 for c in cmds if c["state"] == "DONE")
    failed = sum(1 for c in cmds if c["state"] == "FAILED")
    running = sum(1 for c in cmds if c["state"] in ("RUNNING", "VERIFYING", "CLAIMED"))
    queued = sum(1 for c in cmds if c["state"] == "QUEUED")

    msg = (
        f"Status @ {now_iso()}\n"
        f"Commands: {done} done | {failed} failed | {running} running | {queued} queued\n"
        f"Agents: {len(agents)} reporting\n"
    )

    # Basic online/offline heuristic from agent snapshot timestamp (supabase returns ISO strings)
    # We report "STALE" if older than threshold; exact parsing avoided; rely on runner freshness typically < 1 min.
    for a in agents[:5]:
        msg += f"- {a['agent_id']}: {a.get('status','?')} (last={a.get('ts','?')})\n"
        if a.get("last_error"):
            msg += f"  last_error: {a['last_error'][:120]}\n"

    msg += "\nRecent:\n"
    for c in cmds[:5]:
        msg += f"- {c['state']} P{c['priority']} {c['title']} ({c['command_id']}) {c['progress']}%\n"

    await tg_send(chat_id, msg)

async def builtin_last(chat_id: str):
    cmds = await sb_select(
        "az_commands",
        f"source_chat_id=eq.{chat_id}&select=command_id,title,state,progress,updated_at&order=updated_at.desc&limit=10"
    )
    if not cmds:
        await tg_send(chat_id, "No recent commands for this chat.")
        return
    msg = "Last 10 commands:\n"
    for c in cmds:
        msg += f"- {c['state']} {c['title']} ({c['command_id']}) {c['progress']}%\n"
    await tg_send(chat_id, msg)

async def builtin_tail(chat_id: str, command_id: str):
    # show last 12 events for that command
    evs = await sb_select(
        "az_events",
        f"command_id=eq.{command_id}&select=ts,severity,event_type,message,source&order=ts.desc&limit=12"
    )
    if not evs:
        await tg_send(chat_id, f"No events found for {command_id}.")
        return
    msg = f"Tail for {command_id} (latest first):\n"
    for e in evs:
        msg += f"- [{e['severity']}] {e['event_type']} {e['source']}: {e['message'][:160]}\n"
    await tg_send(chat_id, msg)

async def builtin_errors(chat_id: str):
    # last 10 critical events globally (or for this chat’s commands if you prefer)
    evs = await sb_select(
        "az_events",
        "severity=eq.critical&select=ts,source,command_id,event_type,message&order=ts.desc&limit=10"
    )
    if not evs:
        await tg_send(chat_id, "No critical errors found.")
        return
    msg = "Last critical errors:\n"
    for e in evs:
        msg += f"- {e['ts']} {e['source']} {e['event_type']} ({e.get('command_id','-')}): {e['message'][:160]}\n"
    await tg_send(chat_id, msg)

async def builtin_cancel(chat_id: str, command_id: str):
    rows = await sb_select("az_commands", f"command_id=eq.{command_id}&select=command_id,state,source_chat_id,title")
    if not rows:
        await tg_send(chat_id, "Not found.")
        return
    cmd = rows[0]
    if cmd.get("source_chat_id") and str(cmd["source_chat_id"]) != str(chat_id):
        await tg_send(chat_id, "Not allowed (different chat).")
        return
    if cmd["state"] in ("DONE", "FAILED", "CANCELLED"):
        await tg_send(chat_id, f"Cannot cancel; already {cmd['state']}.")
        return

    await sb_patch("az_commands", f"command_id=eq.{command_id}", {
        "state": "CANCELLED",
        "state_reason": "Cancelled from Telegram",
        "progress": 100
    })
    await emit_event("control_plane", command_id, "warn", "state_change", "Command cancelled", {"state": "CANCELLED"})
    await tg_send(chat_id, f"Cancelled {command_id} ({cmd.get('title','')}).")

# ----------------- FastAPI routes -----------------
@app.get("/health")
async def health():
    return {"ok": True, "ts": now_iso(), "service": "titan-bridge-control-plane", "version": "3.1.0"}

@app.post("/telegram/webhook")
async def telegram_webhook(request: Request):
    if TELEGRAM_WEBHOOK_SECRET:
        secret = request.headers.get("x-telegram-bot-api-secret-token", "")
        if secret != TELEGRAM_WEBHOOK_SECRET:
            raise HTTPException(403, {"error": "bad_telegram_secret"})

    update = await request.json()
    msg = update.get("message") or update.get("edited_message") or {}
    chat = msg.get("chat") or {}
    chat_id = str(chat.get("id", ""))
    message_id = str(msg.get("message_id", ""))
    text = (msg.get("text") or "").strip()

    if not chat_id:
        return {"ok": True, "ignored": True}

    # Security Check
    if ALLOWED_CHAT_IDS and chat_id not in ALLOWED_CHAT_IDS:
        print(f"Blocked unauthorized chat_id: {chat_id}") # Log to Vercel
        return {"ok": True, "ignored": True}

    if not text:
        await tg_send(chat_id, "Text commands only for v3.1. Type: help")
        return {"ok": True}

    parsed = parse_command(text)

    # builtins
    b = parsed.get("builtin")
    if b == "help":
        await builtin_help(chat_id); return {"ok": True}
    if b == "status":
        await builtin_status(chat_id); return {"ok": True}
    if b == "last":
        await builtin_last(chat_id); return {"ok": True}
    if b == "tail":
        await builtin_tail(chat_id, parsed["id"]); return {"ok": True}
    if b == "errors":
        await builtin_errors(chat_id); return {"ok": True}
    if b == "projects":
        await builtin_projects(chat_id); return {"ok": True}
    if b == "cancel":
        await builtin_cancel(chat_id, parsed["id"]); return {"ok": True}

    record = {
        "origin": "telegram",
        "requested_by": "founder",
        "source_chat_id": chat_id,
        "source_message_id": message_id,
        "title": parsed["title"],
        "intent": parsed["intent"],
        "objective": parsed["objective"],
        "targets": ["runner_win"],
        "inputs": parsed["inputs"],
        "constraints": [],
        "priority": parsed.get("priority", 1),
        "state": "QUEUED",
        "progress": 0
    }

    inserted = await sb_insert("az_commands", record)
    cid = str(inserted.get("command_id"))

    await emit_event("control_plane", cid, "info", "state_change", "Command queued from Telegram", {"state": "QUEUED"})
    await tg_send(chat_id, f"Queued: {cid}\nIntent: {record['intent']}\nInputs: {record['inputs']}")
    return {"ok": True}
