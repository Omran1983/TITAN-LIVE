<#
    Jarvis-Brain.ps1
    ----------------
    Launcher for the "Local God Mode" Python Engine.
    Loads environment variables and executes the Reasoning Agent.
#>

param(
    [string]$Goal
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Load Environment
. "$ScriptDir\Jarvis-LoadEnv.ps1"

# 2. Check for Python
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "CRITICAL: Python not found in path."
    exit 1
}

# 3. Check for Brain Script
$BrainScript = "$ScriptDir\..\py\jarvis_brain_local.py"
if (-not (Test-Path $BrainScript)) {
    Write-Error "CRITICAL: Brain script missing at $BrainScript"
    exit 1
}

# 4. Execute
Write-Host ">>> ACTIVATING JARVIS BRAIN (PHASE 13) <<<" -ForegroundColor Hex "#00FFFF"
if ($Goal) {
    Write-Host "GOAL: $Goal" -ForegroundColor Client
    python $BrainScript "$Goal"
}
else {
    Write-Host "Interactive Mode" -ForegroundColor Gray
    python $BrainScript "Introduce yourself and check system status."
}
