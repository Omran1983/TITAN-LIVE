import os, time, subprocess, traceback
from typing import Optional, Tuple

import httpx
import psutil

try:
    import tomllib  # py3.11+
except Exception:
    import tomli as tomllib

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_SERVICE_ROLE_KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]

AGENT_ID = os.environ.get("RUNNER_AGENT_ID", "runner_win")
POLL_SECONDS = int(os.environ.get("POLL_SECONDS", "2"))

TELEGRAM_BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "")

PROJECTS_DIR = os.path.join(os.path.dirname(__file__), "projects")

def now_iso():
    return time.strftime("%Y-%m-%dT%H:%M:%S%z")

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

def sb_get(table: str, query: str) -> list:
    r = httpx.get(f"{sb_url(table)}?{query}", headers=sb_headers(), timeout=20)
    if r.status_code >= 300:
        raise RuntimeError(f"Supabase GET failed: {r.status_code} {r.text}")
    return r.json()

def sb_post(table: str, payload: dict) -> dict:
    r = httpx.post(sb_url(table), headers=sb_headers(), json=payload, timeout=20)
    if r.status_code >= 300:
        raise RuntimeError(f"Supabase POST failed: {r.status_code} {r.text}")
    data = r.json()
    return data[0] if isinstance(data, list) and data else payload

def sb_patch(table: str, query: str, patch: dict) -> list:
    r = httpx.patch(f"{sb_url(table)}?{query}", headers=sb_headers(), json=patch, timeout=20)
    if r.status_code >= 300:
        raise RuntimeError(f"Supabase PATCH failed: {r.status_code} {r.text}")
    return r.json()

def emit(command_id: Optional[str], severity: str, event_type: str, message: str, payload: dict):
    # Keep payload small and tail-friendly
    sb_post("az_events", {
        "source": AGENT_ID,
        "command_id": command_id,
        "severity": severity,
        "event_type": event_type,
        "message": message,
        "payload": payload
    })

def upsert_health(status: str, current_command_id: Optional[str], last_error: Optional[str] = None):
    metrics = {
        "cpu": psutil.cpu_percent(interval=0.1),
        "mem_percent": psutil.virtual_memory().percent,
        "ts": now_iso()
    }
    headers = sb_headers()
    headers["Prefer"] = "resolution=merge-duplicates,return=representation"
    snap = {
        "agent_id": AGENT_ID,
        "ts": "now()",
        "status": status,
        "current_command_id": current_command_id,
        "last_error": last_error,
        "metrics": metrics
    }
    try:
        httpx.post(sb_url("az_health_snapshots"), headers=headers, json=snap, timeout=20)
    except Exception:
        pass

def tg_send(chat_id: str, text: str):
    if not TELEGRAM_BOT_TOKEN or not chat_id:
        return
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    try:
        httpx.post(url, json={"chat_id": chat_id, "text": text[:3900]}, timeout=20)
    except Exception:
        pass

def fetch_next() -> Optional[dict]:
    # Legacy Runner: Ignore v2.* intents
    # 'intent=not.like.v2.*'
    rows = sb_get("az_commands", "state=eq.QUEUED&intent=not.like.v2.*&select=*&order=priority.asc,created_at.asc&limit=1")
    return rows[0] if rows else None

def claim(cmd: dict) -> dict:
    cid = str(cmd["command_id"])
    patched = sb_patch("az_commands", f"command_id=eq.{cid}", {
        "state": "CLAIMED",
        "assigned_agent_id": AGENT_ID,
        "claimed_at": "now()",
        "progress": 5
    })
    emit(cid, "info", "state_change", "Claimed", {"state": "CLAIMED"})
    return patched[0] if patched else cmd

def set_state(cid: str, state: str, progress: int, reason: Optional[str] = None):
    patch = {"state": state, "progress": progress}
    if reason:
        patch["state_reason"] = reason
    if state == "RUNNING":
        patch["started_at"] = "now()"
    if state in ("DONE", "FAILED", "CANCELLED"):
        patch["finished_at"] = "now()"
    sb_patch("az_commands", f"command_id=eq.{cid}", patch)
    emit(cid, "info" if state != "FAILED" else "critical", "state_change", f"State={state}", {"state": state, "progress": progress})

def load_project(project_id: str) -> dict:
    path = os.path.join(PROJECTS_DIR, f"{project_id}.toml")
    if not os.path.exists(path):
        raise FileNotFoundError(f"Project not found: {path}")
    with open(path, "rb") as f:
        return tomllib.load(f)

def run_shell(kind: str, command: str, cwd: Optional[str] = None) -> Tuple[int, str, str]:
    if kind == "powershell":
        proc = subprocess.run(["powershell", "-NoProfile", "-Command", command], cwd=cwd, capture_output=True, text=True)
    elif kind == "cmd":
        proc = subprocess.run(command, cwd=cwd, capture_output=True, text=True, shell=True)
    elif kind == "python":
        proc = subprocess.run(["python", "-c", command], cwd=cwd, capture_output=True, text=True)
    elif kind == "node":
        proc = subprocess.run(["node", "-e", command], cwd=cwd, capture_output=True, text=True)
    elif kind == "docker":
        proc = subprocess.run(["powershell", "-NoProfile", "-Command", f"docker {command}"], cwd=cwd, capture_output=True, text=True)
    else:
        raise ValueError(f"Unknown kind: {kind}")
    return proc.returncode, (proc.stdout or "")[-6000:], (proc.stderr or "")[-6000:]

def run_project(cid: str, project_id: str, project: dict) -> dict:
    name = project.get("project", {}).get("name", project_id)
    steps = project.get("steps", [])
    if not isinstance(steps, list) or not steps:
        raise RuntimeError("Project has no steps")

    emit(cid, "info", "log", f"Project start: {name}", {"project_id": project_id})
    set_state(cid, "RUNNING", 15)

    for i, step in enumerate(steps, start=1):
        step_name = step.get("name", f"step_{i}")
        kind = step.get("kind", "powershell")
        cmd = step.get("cmd", "")
        cwd = step.get("cwd")

        emit(cid, "info", "log", f"Step {i}/{len(steps)}: {step_name}", {"kind": kind, "cwd": cwd})
        rc, out, err = run_shell(kind, cmd, cwd=cwd)

        # Store useful tails as events for tail <id>
        if out.strip():
            emit(cid, "info", "log", f"stdout_tail: {out[-500:].strip()}", {"step": step_name})
        if err.strip():
            emit(cid, "warn" if rc == 0 else "critical", "log", f"stderr_tail: {err[-500:].strip()}", {"step": step_name})

        sb_patch("az_commands", f"command_id=eq.{cid}", {"progress": int(15 + 70 * (i / len(steps)))})

        if rc != 0:
            raise RuntimeError(f"Step failed: {step_name} rc={rc}")

    return {
        "ok": True,
        "agent": AGENT_ID,
        "ts": now_iso(),
        "human_summary": f"Project '{name}' completed successfully.",
        "project_id": project_id
    }

def run_command(cmd: dict) -> dict:
    intent = cmd.get("intent", "")
    inputs = cmd.get("inputs", {}) or {}

    if intent == "project.run":
        project_id = inputs.get("project_id") or "titan_smoke"
        project = load_project(project_id)
        return run_project(str(cmd["command_id"]), project_id, project)

    if intent == "shell.powershell":
        rc, out, err = run_shell("powershell", inputs.get("command", ""))
        if rc != 0:
            raise RuntimeError(f"PowerShell failed rc={rc}")
        return {"ok": True, "ts": now_iso(), "human_summary": "PowerShell executed.", "stdout_tail": out[-500:]}

    if intent == "shell.cmd":
        rc, out, err = run_shell("cmd", inputs.get("command", ""))
        if rc != 0:
            raise RuntimeError(f"CMD failed rc={rc}")
        return {"ok": True, "ts": now_iso(), "human_summary": "CMD executed.", "stdout_tail": out[-500:]}

    if intent == "shell.python":
        rc, out, err = run_shell("python", inputs.get("command", ""))
        if rc != 0:
            raise RuntimeError(f"Python failed rc={rc}")
        return {"ok": True, "ts": now_iso(), "human_summary": "Python executed.", "stdout_tail": out[-500:]}

    if intent == "shell.node":
        rc, out, err = run_shell("node", inputs.get("command", ""))
        if rc != 0:
            raise RuntimeError(f"Node failed rc={rc}")
        return {"ok": True, "ts": now_iso(), "human_summary": "Node executed.", "stdout_tail": out[-500:]}

    if intent == "shell.docker":
        rc, out, err = run_shell("docker", inputs.get("command", ""))
        if rc != 0:
            raise RuntimeError(f"Docker failed rc={rc}")
        return {"ok": True, "ts": now_iso(), "human_summary": "Docker executed.", "stdout_tail": out[-500:]}

    # fallback
    project = load_project("titan_smoke")
    return run_project(str(cmd["command_id"]), "titan_smoke", project)

def finalize(cid: str, ok: bool, payload: dict, chat_id: str):
    if ok:
        sb_patch("az_commands", f"command_id=eq.{cid}", {"state": "DONE", "progress": 100, "result": payload, "error": None})
        emit(cid, "info", "state_change", "DONE", {"state": "DONE"})
        tg_send(chat_id, f"DONE {cid}\n{payload.get('human_summary','(no summary)')}")
    else:
        sb_patch("az_commands", f"command_id=eq.{cid}", {"state": "FAILED", "progress": 100, "error": payload})
        emit(cid, "critical", "state_change", "FAILED", {"state": "FAILED"})
        tg_send(chat_id, f"FAILED {cid}\n{payload.get('message','(no message)')}\nTry: tail {cid}")

def main():
    emit(None, "info", "log", "Runner started", {"agent_id": AGENT_ID})
    upsert_health("IDLE", None)

    while True:
        try:
            upsert_health("IDLE", None)
            cmd = fetch_next()
            if not cmd:
                time.sleep(POLL_SECONDS); continue

            if cmd.get("state") == "CANCELLED":
                time.sleep(POLL_SECONDS); continue

            cmd = claim(cmd)
            cid = str(cmd["command_id"])
            chat_id = str(cmd.get("source_chat_id") or "")

            # Runner-side cancel check (if cancelled after claim)
            refreshed = sb_get("az_commands", f"command_id=eq.{cid}&select=state")[0]
            if refreshed.get("state") == "CANCELLED":
                emit(cid, "warn", "state_change", "Cancelled before run", {})
                time.sleep(POLL_SECONDS)
                continue

            set_state(cid, "RUNNING", 15)
            upsert_health("RUNNING", cid)

            try:
                result = run_command(cmd)
                finalize(cid, True, result, chat_id)
                upsert_health("IDLE", None)
            except Exception as e:
                err = {"message": str(e), "traceback_tail": traceback.format_exc()[-2000:]}
                finalize(cid, False, err, chat_id)
                upsert_health("ERROR", cid, last_error=str(e))

        except Exception:
            time.sleep(POLL_SECONDS)

if __name__ == "__main__":
    main()
