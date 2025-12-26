from __future__ import annotations
import json, subprocess, os, glob
from pathlib import Path
from typing import Dict, Any
from fastapi import FastAPI, Body, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles

ROOT    = Path(r"F:\AION-ZERO\py")
VENV_PY = Path(r"F:\AION-ZERO\py\venv\Scripts\python.exe")
CF_ROOT = Path(r"F:\Jarvis\cf-worker")
OUT_WEB = CF_ROOT / "out" / "web"

ALLOWED = {"ping","cache-put","cache-get","cache_put","cache_get"}

app = FastAPI(title="AOGRL Ops Dashboard")

# ---- API ----
@app.get("/api/health")
def api_health():
    hfile = CF_ROOT / "out" / "health.json"
    try:
        data = json.loads(hfile.read_text(encoding="utf-8"))
    except Exception:
        data = {"http": False, "public_url": None, "ts": None}
    return data

@app.get("/api/commands")
def api_commands():
    return {"allowed": sorted(ALLOWED)}

@app.get("/api/logs")
def api_logs(tail: int = 60):
    logs = sorted(glob.glob(str(CF_ROOT / "logs" / "cloudflared_*_*.log")), key=os.path.getmtime, reverse=True)
    path = logs[0] if logs else None
    if not path:
        return {"log": "(no logs)"}
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()[-tail:]
        return {"path": path, "log": "".join(lines)}
    except Exception as e:
        return {"path": path, "log": f"(error reading log: {e})"}

@app.post("/api/run")
def api_run(payload: Dict[str, Any] = Body(...)):
    cmd  = str(payload.get("cmd","")).strip()
    args = payload.get("args", [])
    if cmd not in ALLOWED:
        raise HTTPException(400, f"Command not allowed: {cmd}")
    pyexe = str(VENV_PY if VENV_PY.exists() else "py")
    cli = ["-m","aogrl_ops_pack.cli", cmd] + list(map(str, args or []))
    try:
        p = subprocess.run([pyexe, *cli], capture_output=True, text=True, timeout=60)
        return {"code": p.returncode, "stdout": p.stdout, "stderr": p.stderr}
    except subprocess.TimeoutExpired:
        raise HTTPException(504, "Command timed out")

# ---- UI ----
UI_DIR = ROOT / "ops" / "dashboard" / "ui"
UI_DIR.mkdir(parents=True, exist_ok=True)
INDEX_HTML = UI_DIR / "index.html"

@app.get("/", response_class=HTMLResponse)
def root():
    # Serve the static website if present; else redirect to /ui
    if OUT_WEB.exists():
        return HTMLResponse((OUT_WEB / "index.html").read_text(encoding="utf-8"))
    return HTMLResponse('<meta http-equiv="refresh" content="0; url=/ui">')

# Mount dashboard under /ui
app.mount("/ui", StaticFiles(directory=str(UI_DIR), html=True), name="ui")
# Also mount static website under /site to access if needed
if OUT_WEB.exists():
    app.mount("/site", StaticFiles(directory=str(OUT_WEB), html=True), name="site")

# Write default dashboard HTML if missing
if not INDEX_HTML.exists():
    INDEX_HTML.write_text("""<!doctype html>
<html>
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>AOGRL Ops</title>
  <style>
    body{font-family:system-ui,Segoe UI,Arial;margin:24px;max-width:980px}
    .card{border:1px solid #ddd;border-radius:12px;padding:16px;margin-bottom:16px;box-shadow:0 1px 3px rgba(0,0,0,.04)}
    button{padding:8px 12px;border-radius:10px;border:1px solid #ccc;cursor:pointer}
    pre{background:#111;color:#0f0;padding:12px;border-radius:10px;overflow:auto;max-height:280px}
    .row{display:flex;gap:8px;flex-wrap:wrap}
    input{padding:8px;border-radius:8px;border:1px solid #ccc}
    small{color:#666}
  </style>
</head>
<body>
  <h1>🛡️ AOGRL Ops Dashboard</h1>

  <div class="card">
    <h3>Health</h3>
    <div>HTTP: <b id="http">?</b></div>
    <div>Public URL: <a id="pub" href="#" target="_blank">...</a></div>
    <div><small id="ts"></small></div>
    <button onclick="refresh()">Refresh</button>
  </div>

  <div class="card">
    <h3>Commands</h3>
    <div class="row">
      <button onclick="run('ping')">Ping</button>
      <input id="ck" placeholder="key" />
      <input id="cv" placeholder="value" />
      <button onclick="run('cache-put',[val('ck'),val('cv')])">Cache Put</button>
      <button onclick="run('cache-get',[val('ck')])">Cache Get</button>
    </div>
    <pre id="out"></pre>
  </div>

  <div class="card">
    <h3>Logs (cloudflared tail)</h3>
    <pre id="logs"></pre>
    <button onclick="logs()">Refresh Logs</button>
  </div>

<script>
const $ = s => document.querySelector(s);
const val = id => document.getElementById(id).value;

async function refresh(){
  const r = await fetch('/api/health'); const j = await r.json();
  $('#http').textContent = j.http ? 'UP' : 'DOWN';
  $('#pub').textContent = j.public_url || '(none)';
  if (j.public_url){ $('#pub').href = j.public_url; }
  $('#ts').textContent = j.ts || '';
}
async function logs(){
  const r = await fetch('/api/logs'); const j = await r.json();
  $('#logs').textContent = (j.log||'').trim();
}
async function run(cmd,args=[]){
  const r = await fetch('/api/run',{method:'POST',headers:{'Content-Type':'application/json'},
    body: JSON.stringify({cmd, args})});
  const j = await r.json();
  $('#out').textContent = JSON.stringify(j,null,2);
}
refresh(); logs();
</script>
</body></html>""", encoding="utf-8")
