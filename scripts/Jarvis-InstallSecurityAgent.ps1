# =====================================================================
# Jarvis-InstallSecurityAgent.ps1  (PS 5.1 Compatible)
# =====================================================================

$ErrorActionPreference = "Stop"

Write-Host "=== Installing Jarvis-SecurityAgent ==="

$root = "F:\AION-ZERO\scripts"
$scriptPath = Join-Path $root "Jarvis-SecurityAgent.ps1"
$wrapperVbs = Join-Path $root "silent-run.vbs"

if (!(Test-Path $scriptPath)) {
    Write-Host "ERROR: SecurityAgent script not found at $scriptPath"
    exit 1
}
if (!(Test-Path $wrapperVbs)) {
    Write-Host "ERROR: silent-run.vbs missing!"
    exit 1
}

# Wrapped call
$wrappedArgs = "`"$wrapperVbs`" `"$scriptPath`""

# Remove old task
Unregister-ScheduledTask -TaskName "Jarvis-SecurityAgent" -Confirm:$false -ErrorAction SilentlyContinue

# Scheduled Task Action
$action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument $wrappedArgs

# 🟦 PS 5.1 COMPATIBLE TRIGGER (Every 5 minutes forever)
$trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date).AddMinutes(1) `
    -RepetitionInterval (New-TimeSpan -Minutes 5) `
    -RepetitionDuration (New-TimeSpan -Days 9999)

# Run as SYSTEM, highest privileges
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

# Register Task
Register-ScheduledTask `
    -TaskName "Jarvis-SecurityAgent" `
    -Description "Jarvis Security Scan Worker" `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    | Out-Null

Write-Host "Task installed successfully."

# Start immediately
Start-ScheduledTask -TaskName "Jarvis-SecurityAgent"
Write-Host "Started Jarvis-SecurityAgent."

Write-Host "=== DONE: SecurityAgent installed & running ==="
