<#
    Jarvis-Talk.ps1
    ---------------
    Opens a secure channel to AION-ZERO.
    Interactive Chat Mode.
#>

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Load Env
. "$ScriptDir\Jarvis-LoadEnv.ps1"

# 2. Check Dependencies
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "Python not found."
    exit 1
}

# 3. Launch Chat
Write-Host ">>> OPENING CHANNEL TO AION-ZERO <<<" -ForegroundColor Hex "#00FF00"
python "$ScriptDir\..\py\jarvis_chat.py"
