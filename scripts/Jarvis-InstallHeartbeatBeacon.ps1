<#
    Jarvis-InstallHeartbeatBeacon.ps1
    ---------------------------------
    Registers a Windows Scheduled Task that runs Jarvis-HeartbeatBeacon.ps1
    every 5 minutes indefinitely.

    The task:
      - Name: Jarvis-HeartbeatBeacon
      - Runs: powershell.exe -NoProfile -ExecutionPolicy Bypass -File Jarvis-HeartbeatBeacon.ps1
      - Trigger: Once (starting 1 minute from now) with 5-min repetition, 1-day duration
        (Windows auto-renews it daily; effectively "forever" for us).

    Usage:
      cd F:\AION-ZERO\scripts
      powershell -NoProfile -ExecutionPolicy Bypass -File .\Jarvis-InstallHeartbeatBeacon.ps1
#>

param()

$ErrorActionPreference = "Stop"

Write-Host "=== Jarvis-InstallHeartbeatBeacon ==="

# Resolve script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "ScriptDir: $scriptDir"

$taskName = "Jarvis-HeartbeatBeacon"

# 1) Remove existing task if present
Write-Host "Removing any existing task '$taskName' (if present)..."
try {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
}
catch {
    Write-Warning "Failed to unregister existing task (may not exist): $($_.Exception.Message)"
}

# 2) Define action
$psExe = "$Env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$heartbeatScript = Join-Path $scriptDir "Jarvis-HeartbeatBeacon.ps1"

if (-not (Test-Path $heartbeatScript)) {
    throw "Heartbeat script not found at: $heartbeatScript"
}

$arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$heartbeatScript`""

$action = New-ScheduledTaskAction -Execute $psExe -Argument $arguments

# 3) Define trigger (every 5 minutes, safe duration)
$now = Get-Date

$trigger = New-ScheduledTaskTrigger `
    -Once `
    -At $now.AddMinutes(1) `
    -RepetitionInterval (New-TimeSpan -Minutes 5) `
    -RepetitionDuration (New-TimeSpan -Days 1)

# 4) Register task
Write-Host "Registering scheduled task '$taskName'..."
try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description "Jarvis Heartbeat Beacon" | Out-Null
    Write-Host "✅ Heartbeat task '$taskName' registered successfully."
}
catch {
    throw "Failed to register scheduled task '$taskName': $($_.Exception.Message)"
}
