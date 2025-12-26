<#
    Jarvis-Citadel.ps1
    ------------------
    Launches The Glass Citadel Dashboard.
    http://127.0.0.1:5000
#>

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Load Env
. "$ScriptDir\Jarvis-LoadEnv.ps1"

# 2. Start Citadel (FastAPI/Uvicorn)
Write-Host ">>> ACTIVATING THE GLASS CITADEL V2 (PORT 9000) <<<" -ForegroundColor Green
$ServerScript = Join-Path "$ScriptDir\.." "citadel\main.py"
Start-Process python -ArgumentList $ServerScript -WindowStyle Minimized

# 3. Open Browser
Start-Sleep -Seconds 3
Start-Process "http://localhost:9000"
