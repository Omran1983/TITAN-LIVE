param(
    [string]$Root = "F:\AION-ZERO",
    [string]$ProjectFolder = "jarvis-hq"
)

# Helper: create dir if missing
function New-Dir {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

# Resolve root paths
$projectRoot = Join-Path $Root $ProjectFolder
$apiDir      = Join-Path $projectRoot "api"
$routersDir  = Join-Path $apiDir "routers"
$runnerDir   = Join-Path $projectRoot "runner"
$telegramDir = Join-Path $projectRoot "telegram"
$configDir   = Join-Path $projectRoot "config"
$dockerDir   = Join-Path $projectRoot "docker"
$logsDir     = Join-Path $projectRoot "logs"
$scriptsDir  = Join-Path $projectRoot "scripts"

Write-Host "Creating Jarvis HQ structure under $projectRoot ..." -ForegroundColor Cyan

# Create directories
New-Dir $projectRoot
New-Dir $apiDir
New-Dir $routersDir
New-Dir $runnerDir
New-Dir $telegramDir
New-Dir $configDir
New-Dir $dockerDir
New-Dir $logsDir
New-Dir $scriptsDir

# --- API: main FastAPI app (Control Plane) ---
$mainPy = @"
from fastapi import FastAPI
from .routers import commands

app = FastAPI(
    title="Jarvis HQ Control Plane",
    version="0.1.0",
    description="Central API for Jarvis/AION-ZERO commands, tools and workers."
)

app.include_router(commands.router, prefix="/api/commands", tags=["commands"])


@app.get("/health")
async def health():
    return {"status": "ok"}
"@
Set-Content -Path (Join-Path $apiDir "main.py") -Value $mainPy -Encoding UTF8

# --- API: schemas (command envelope etc.) ---
$schemasPy = @"
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime


class CommandPayload(BaseModel):
    tool_name: str = Field(..., description="Name of the tool to execute, e.g. 'ps.run' or 'python.script'")
    args: Dict[str, Any] = Field(default_factory=dict, description="Arguments to the tool")


class EnqueuedCommand(BaseModel):
    id: Optional[str] = None
    source: str = "manual"
    priority: int = 10
    payload: CommandPayload
    requested_by: Optional[str] = None
    created_at: Optional[datetime] = None
"@
Set-Content -Path (Join-Path $apiDir "schemas.py") -Value $schemasPy -Encoding UTF8

# --- API: basic config loader using TOML (no secrets) ---
$configPy = @"
from pathlib import Path
from typing import Any, Dict
import os

try:
    import tomllib  # Python 3.11+
except ModuleNotFoundError:
    import tomli as tomllib  # type: ignore


def load_config() -> Dict[str, Any]:
    root = Path(__file__).resolve().parents[1]
    base = root / "config" / "config.base.toml"
    env = root / "config" / "config.dev.toml"

    data: Dict[str, Any] = {}
    if base.exists():
        data.update(tomllib.loads(base.read_text(encoding="utf-8")))
    if env.exists():
        data.update(tomllib.loads(env.read_text(encoding="utf-8")))

    # Environment variables override TOML
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

    if supabase_url:
        data["supabase_url"] = supabase_url
    if supabase_key:
        data["supabase_service_role_key"] = supabase_key

    return data
"@
Set-Content -Path (Join-Path $apiDir "config.py") -Value $configPy -Encoding UTF8

# --- API: router for commands (stub) ---
$commandsPy = @"
from fastapi import APIRouter, HTTPException
from typing import List
from ..schemas import EnqueuedCommand, CommandPayload

router = APIRouter()


@router.post("/", response_model=EnqueuedCommand)
async def enqueue_command(cmd: EnqueuedCommand):
    # TODO: persist into Supabase az_commands table
    # For now, just echo back with fake id
    if not cmd.payload or not cmd.payload.tool_name:
        raise HTTPException(status_code=400, detail="tool_name is required")

    cmd.id = cmd.id or "local-test-id"
    return cmd


@router.get("/", response_model=List[EnqueuedCommand])
async def list_commands():
    # TODO: list from Supabase
    return []
"@
Set-Content -Path (Join-Path $routersDir "commands.py") -Value $commandsPy -Encoding UTF8

# --- API: __init__ files ---
Set-Content -Path (Join-Path $apiDir "__init__.py") -Value "" -Encoding UTF8
Set-Content -Path (Join-Path $routersDir "__init__.py") -Value "" -Encoding UTF8

# --- RUNNER: Python executor skeleton ---
$runnerPy = @"
import subprocess
from typing import Dict, Any


def run_powershell(command: str) -> Dict[str, Any]:
    \"\"\"Run a PowerShell command and capture output.\"\"\"
    try:
        completed = subprocess.run(
            ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", command],
            capture_output=True,
            text=True,
            check=False,
        )
        return {
            "ok": completed.returncode == 0,
            "code": completed.returncode,
            "stdout": completed.stdout,
            "stderr": completed.stderr,
        }
    except Exception as e:
        return {"ok": False, "code": -1, "stdout": "", "stderr": str(e)}


if __name__ == "__main__":
    # Simple smoke test
    result = run_powershell("Get-Date")
    print(result)
"@
Set-Content -Path (Join-Path $runnerDir "executor.py") -Value $runnerPy -Encoding UTF8

# --- TELEGRAM: gateway skeleton ---
$telegramPy = @"
import os
import logging
from dataclasses import dataclass

from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, ContextTypes, filters


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@dataclass
class BotConfig:
    token: str


def load_config() -> BotConfig:
    token = os.getenv("TELEGRAM_BOT_TOKEN", "")
    if not token:
        raise RuntimeError("TELEGRAM_BOT_TOKEN is not set in environment")
    return BotConfig(token=token)


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    await update.message.reply_text("Jarvis HQ at your service. Send a command to enqueue.")


async def handle_text(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    text = (update.message.text or "").strip()
    if not text:
        return

    # TODO: call Control Plane /api/commands and enqueue safely
    logger.info("Received text from %s: %s", update.effective_user.id, text)
    await update.message.reply_text(f"Command received (not yet enqueued): `{text}`", parse_mode="Markdown")


async def main() -> None:
    cfg = load_config()
    app = Application.builder().token(cfg.token).build()

    app.add_handler(CommandHandler("start", start))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_text))

    logger.info("Starting Telegram bot...")
    await app.run_polling()


if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
"@
Set-Content -Path (Join-Path $telegramDir "bot.py") -Value $telegramPy -Encoding UTF8

# --- CONFIG: base + dev TOML ---
$configBaseToml = @"
[app]
name = "jarvis-hq"
environment = "base"

[logging]
level = "INFO"

[queue]
default_priority = 10
"@
Set-Content -Path (Join-Path $configDir "config.base.toml") -Value $configBaseToml -Encoding UTF8

$configDevToml = @"
[app]
environment = "dev"

[fastapi]
host = "127.0.0.1"
port = 8005
"@
Set-Content -Path (Join-Path $configDir "config.dev.toml") -Value $configDevToml -Encoding UTF8

# --- ENV example ---
$envExample = @"
# Jarvis HQ environment example

# Supabase
SUPABASE_URL=https://YOUR-PROJECT.supabase.co
SUPABASE_SERVICE_ROLE_KEY=YOUR-SERVICE-ROLE-KEY

# Telegram
TELEGRAM_BOT_TOKEN=YOUR-TELEGRAM-BOT-TOKEN
"@
Set-Content -Path (Join-Path $projectRoot ".env.example") -Value $envExample -Encoding UTF8

# --- requirements.txt for API + Telegram bot ---
$requirementsTxt = @"
fastapi
uvicorn[standard]
pydantic
python-telegram-bot==21.6
tomli; python_version < "3.11"
"@
Set-Content -Path (Join-Path $projectRoot "requirements.txt") -Value $requirementsTxt -Encoding UTF8

# --- Docker Compose skeleton (API + Telegram + future workers) ---
$composeYml = @"
version: "3.9"

services:
  jarvis-api:
    image: python:3.11-slim
    working_dir: /app
    volumes:
      - ../jarvis-hq:/app
    command: >
      sh -c "pip install --no-cache-dir -r requirements.txt &&
             uvicorn api.main:app --host 0.0.0.0 --port 8005"
    environment:
      - SUPABASE_URL
      - SUPABASE_SERVICE_ROLE_KEY
    ports:
      - "8005:8005"
    networks:
      - jarvis-net

  jarvis-telegram:
    image: python:3.11-slim
    working_dir: /app
    volumes:
      - ../jarvis-hq:/app
    command: >
      sh -c "pip install --no-cache-dir -r requirements.txt &&
             python telegram/bot.py"
    environment:
      - TELEGRAM_BOT_TOKEN
      - SUPABASE_URL
      - SUPABASE_SERVICE_ROLE_KEY
    networks:
      - jarvis-net

networks:
  jarvis-net:
    driver: bridge
"@
Set-Content -Path (Join-Path $dockerDir "docker-compose.yml") -Value $composeYml -Encoding UTF8

# --- Simple helper scripts to run locally (without Docker) ---
$runApiPs1 = @"
param(
    [string]$Port = "8005"
)

`$here = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$root = Split-Path -Parent `$here

Set-Location `$root
python -m uvicorn api.main:app --host 127.0.0.1 --port `$Port --reload
"@
Set-Content -Path (Join-Path $scriptsDir "Run-Api.ps1") -Value $runApiPs1 -Encoding UTF8

$runTelegramPs1 = @"
`$here = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$root = Split-Path -Parent `$here

Set-Location `$root
python telegram/bot.py
"@
Set-Content -Path (Join-Path $scriptsDir "Run-TelegramBot.ps1") -Value $runTelegramPs1 -Encoding UTF8

# --- README ---
$readme = @"
# Jarvis HQ

Central control plane for Jarvis / AION-ZERO.

Structure:
- api/          FastAPI control-plane API
- runner/       Local executors (PowerShell, Python, etc.)
- telegram/     Telegram -> Jarvis command gateway
- config/       TOML-based config (non-secret)
- docker/       Docker Compose definitions
- scripts/      Helper scripts (Run-Api, Run-TelegramBot)
- logs/         Runtime logs

Next steps:
1. Create a virtualenv and install requirements.
2. Configure .env from .env.example.
3. Run API and Telegram bot (locally or via Docker).
4. Wire Supabase az_commands and full queue logic.
"@
Set-Content -Path (Join-Path $projectRoot "README.md") -Value $readme -Encoding UTF8

Write-Host "Jarvis HQ skeleton created at $projectRoot" -ForegroundColor Green
