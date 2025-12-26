<#
    Jarvis-Puppet.ps1
    -----------------
    Launches AION-ZERO Browser Automation.
    Usage: .\Jarvis-Puppet.ps1 -Url "https://chatgpt.com"
#>

param(
    [string]$Url = "https://google.com"
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Load Env
. "$ScriptDir\Jarvis-LoadEnv.ps1"

# 2. Launch Puppet
Write-Host ">>> ACTIVATING PUPPET MASTER <<<" -ForegroundColor Hex "#FF00FF"
python "$ScriptDir\..\py\jarvis_puppet.py" "$Url"
