<#
    Jarvis-RevenueGenerator.ps1
    ---------------------------
    Phase 17 Update: Python Launcher.
    Logic moved to: py/jarvis_revenue_gen.py
#>

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Load Env
. "$ScriptDir\Jarvis-LoadEnv.ps1"

# 2. Run Python Logic
Write-Host "[RevenueGen] Launching Python Engine..." -ForegroundColor Cyan
python "$ScriptDir\..\py\jarvis_revenue_gen.py"
