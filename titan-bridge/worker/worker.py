import os
import json
import time
import asyncio
import tomllib
from typing import Any, Dict, List, Optional, Tuple
from dataclasses import dataclass
from enum import Enum

import httpx
import subprocess


def load_toml(path: str) -> dict:
    with open(path, "rb") as f:
        return tomllib.load(f)

CFG = load_toml(os.environ.get("TITAN_CONFIG", "config/base.toml"))

SUPABASE_URL = os.environ.get(CFG["supabase"]["url_env"], "")
SUPABASE_SERVICE_KEY = os.environ.get(CFG["supabase"]["service_key_env"], "")
SUPABASE_SCHEMA = CFG["supabase"].get("schema", "public")

POLL_INTERVAL = int(CFG["worker"]["poll_interval_seconds"])
STALE_SECONDS = int(CFG["worker"]["stale_command_seconds"])

AUTOPILOT_ENABLED = bool(CFG["authority"]["autopilot_enabled"])
DEFAULT_AUTH = CFG["authority"].get("default_level", "L1")

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    raise RuntimeError("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars.")


def sb_headers() -> Dict[str, str]:
    return {
        "apikey": SUPABASE_SERVICE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Prefer": "return=representation",
    }

def sb_url(table: str) -> str:
    return f"{SUPABASE_URL}/rest/v1/{table}"

async def sb_get(table: str, query: str) -> list:
    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.get(f"{sb_url(table)}?{query}", headers=sb_headers())
        if r.status_code >= 300:
            raise RuntimeError(f"Supabase GET failed: {r.status_code} {r.text}")
        return r.json()

async def sb_post(table: str, payload: dict) -> dict:
    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.post(sb_url(table), headers=sb_headers(), json=payload)
        if r.status_code >= 300:
            raise RuntimeError(f"Supabase POST failed: {r.status_code} {r.text}")
        data = r.json()
        return data[0] if isinstance(data, list) and data else payload

async def sb_patch(table: str, match_query: str, patch: dict) -> list:
    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.patch(f"{sb_url(table)}?{match_query}", headers=sb_headers(), json=patch)
        if r.status_code >= 300:
            raise RuntimeError(f"Supabase PATCH failed: {r.status_code} {r.text}")
        return r.json()


def authority_rank(level: str) -> int:
    return {"L0": 0, "L1": 1, "L2": 2, "L3": 3, "L4": 4}.get(level, 1)

def autopilot_allows(level: str) -> bool:
    if AUTOPILOT_ENABLED:
        return True
    # If autopilot disabled, allow only L0-L1 without approval
    return authority_rank(level) <= 1


async def emit_event(source: str, command_id: Optional[str], severity: str, event_type: str, message: str, payload: dict):
    await sb_post("az_events", {
        "source": source,
        "command_id": command_id,
        "severity": severity,
        "event_type": event_type,
        "message": message,
        "payload": payload
    })


async def fetch_next_command() -> Optional[dict]:
    # Order: queued first, highest priority (lower number), oldest first
    rows = await sb_get(
        "az_commands",
        "state=eq.QUEUED&select=*"
        "&order=priority.asc,created_at.asc"
        "&limit=1"
    )
    return rows[0] if rows else None


async def choose_agent(targets: List[str]) -> Optional[dict]:
    # Simple heuristic: map target keywords to agent capabilities.
    agents = await sb_get("az_agents", "enabled=eq.true&select=*")
    wanted = set([t.lower() for t in targets])
    best = None
    best_score = -1
    for a in agents:
        caps = a.get("capabilities", [])
        caps_set = set([str(c).lower() for c in caps]) if isinstance(caps, list) else set()
        score = len(wanted.intersection(caps_set)) if wanted else 0
        if score > best_score:
            best_score = score
            best = a
    return best


async def claim_command(cmd: dict, agent_id: str) -> dict:
    command_id = cmd["command_id"]
    patched = await sb_patch("az_commands", f"command_id=eq.{command_id}", {
        "state": "CLAIMED",
        "assigned_agent_id": agent_id,
        "claimed_at": "now()",
        "progress": 5
    })
    await emit_event("control_plane", command_id, "info", "state_change", f"Command claimed by {agent_id}", {"state": "CLAIMED"})
    return patched[0] if patched else cmd


async def mark_needs_approval(cmd: dict, reason: str) -> None:
    command_id = cmd["command_id"]
    await sb_patch("az_commands", f"command_id=eq.{command_id}", {
        "state": "NEEDS_APPROVAL",
        "state_reason": reason,
        "progress": 0
    })
    await emit_event("control_plane", command_id, "warn", "approval_required", reason, {"state": "NEEDS_APPROVAL"})


async def run_local_agent(agent: dict, cmd: dict) -> Tuple[bool, dict]:
    # local_entrypoint should be a python file path
    entry = agent.get("local_entrypoint")
    if not entry:
        return False, {"error": "missing_local_entrypoint"}

    payload = {
        "command_id": cmd["command_id"],
        "title": cmd["title"],
        "intent": cmd["intent"],
        "objective": cmd["objective"],
        "targets": cmd.get("targets", []),
        "constraints": cmd.get("constraints", []),
        "inputs": cmd.get("inputs", {}),
        "definition_of_done": cmd.get("definition_of_done", []),
    }

    try:
        p = subprocess.run(
            ["python", entry],
            input=json.dumps(payload).encode("utf-8"),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=int(CFG["limits"]["max_runtime_seconds"])
        )
        if p.returncode != 0:
            return False, {"error": "agent_failed", "stderr": p.stderr.decode("utf-8", "ignore")[:4000]}
        out = p.stdout.decode("utf-8", "ignore").strip()
        obj = json.loads(out) if out.startswith("{") else {"raw": out[:4000]}
        return True, obj
    except subprocess.TimeoutExpired:
        return False, {"error": "agent_timeout"}
    except Exception as e:
        return False, {"error": "agent_exception", "detail": str(e)}


async def run_http_agent(agent: dict, cmd: dict) -> Tuple[bool, dict]:
    url = agent.get("http_endpoint")
    if not url:
        return False, {"error": "missing_http_endpoint"}

    payload = {
        "command_id": cmd["command_id"],
        "intent": cmd["intent"],
        "objective": cmd["objective"],
        "inputs": cmd.get("inputs", {}),
        "constraints": cmd.get("constraints", []),
    }

    try:
        async with httpx.AsyncClient(timeout=60) as client:
            r = await client.post(url.rstrip("/") + "/run", json=payload)
            if r.status_code >= 300:
                return False, {"error": "http_agent_failed", "status": r.status_code, "body": r.text[:2000]}
            return True, r.json()
    except Exception as e:
        return False, {"error": "http_agent_exception", "detail": str(e)}


async def run_assigned_agent(agent: dict, cmd: dict) -> Tuple[bool, dict]:
    transport = agent.get("transport", "LOCAL")
    if transport == "HTTP":
        return await run_http_agent(agent, cmd)
    return await run_local_agent(agent, cmd)


async def finalize(cmd: dict, ok: bool, result: dict):
    command_id = cmd["command_id"]
    if ok:
        await sb_patch("az_commands", f"command_id=eq.{command_id}", {
            "state": "DONE",
            "finished_at": "now()",
            "progress": 100,
            "result": result,
            "error": None
        })
        await emit_event("control_plane", command_id, "info", "state_change", "Command completed", {"state": "DONE"})
    else:
        await sb_patch("az_commands", f"command_id=eq.{command_id}", {
            "state": "FAILED",
            "finished_at": "now()",
            "progress": 100,
            "error": result
        })
        await emit_event("control_plane", command_id, "critical", "state_change", "Command failed", {"state": "FAILED", "error": result})


async def main():
    print("Worker started.")
    # Bootstrap: ensure default agents exist (local examples)
    await ensure_default_agents()

    while True:
        try:
            cmd = await fetch_next_command()
            if not cmd:
                await asyncio.sleep(POLL_INTERVAL)
                continue

            # Authority gating
            required = cmd.get("authority_required", DEFAULT_AUTH)
            if not autopilot_allows(required):
                if not cmd.get("approved", False):
                    await mark_needs_approval(cmd, f"Requires {required} and autopilot is disabled.")
                    await asyncio.sleep(POLL_INTERVAL)
                    continue

            targets = cmd.get("targets", [])
            agent = await choose_agent(targets)
            if not agent:
                await mark_needs_approval(cmd, "No enabled agent found for targets.")
                await asyncio.sleep(POLL_INTERVAL)
                continue

            cmd = await claim_command(cmd, agent["agent_id"])
            await sb_patch("az_commands", f"command_id=eq.{cmd['command_id']}", {
                "state": "RUNNING",
                "started_at": "now()",
                "progress": 15
            })
            await emit_event("control_plane", cmd["command_id"], "info", "state_change", "Command running", {"state": "RUNNING", "agent": agent["agent_id"]})

            ok, out = await run_assigned_agent(agent, cmd)

            # Optional VERIFYING stage (if agent returns verify_required=true)
            if ok and isinstance(out, dict) and out.get("verify_required") is True:
                await sb_patch("az_commands", f"command_id=eq.{cmd['command_id']}", {
                    "state": "VERIFYING",
                    "progress": 80
                })
                await emit_event("control_plane", cmd["command_id"], "info", "state_change", "Verifying", {"state": "VERIFYING"})
                # For v1, trust agent’s internal verification report
                # (Later: run Inspector/Verifier automatically here)

            await finalize(cmd, ok, out)

        except Exception as e:
            print("Worker loop error:", e)

        await asyncio.sleep(POLL_INTERVAL)


async def ensure_default_agents():
    # Insert if missing (idempotent via select)
    existing = await sb_get("az_agents", "select=agent_id")
    existing_ids = {a["agent_id"] for a in existing}

    defaults = [
        {
            "agent_id": "doctor_local",
            "name": "Doctor (Local)",
            "transport": "LOCAL",
            "local_entrypoint": "worker/agents_local/doctor_agent.py",
            "capabilities": ["doctor","bugfix"],
            "max_concurrency": 1,
            "enabled": True
        },
        {
            "agent_id": "inspector_local",
            "name": "Inspector (Local)",
            "transport": "LOCAL",
            "local_entrypoint": "worker/agents_local/inspector_agent.py",
            "capabilities": ["inspector","site_health"],
            "max_concurrency": 1,
            "enabled": True
        },
        {
            "agent_id": "verifier_local",
            "name": "Verifier (Local)",
            "transport": "LOCAL",
            "local_entrypoint": "worker/agents_local/verifier_agent.py",
            "capabilities": ["verifier","tests"],
            "max_concurrency": 1,
            "enabled": True
        },
    ]

    for d in defaults:
        if d["agent_id"] not in existing_ids:
            await sb_post("az_agents", d)
            await emit_event("control_plane", None, "info", "agent_registered", f"Registered agent {d['agent_id']}", {"agent": d})


if __name__ == "__main__":
    asyncio.run(main())
