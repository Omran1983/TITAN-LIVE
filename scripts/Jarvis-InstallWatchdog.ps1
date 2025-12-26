$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TaskName  = "Jarvis-HealthWatchdog"
$PsPath    = Join-Path $ScriptDir "Jarvis-Watchdog.ps1"

Write-Host "=== Jarvis-InstallWatchdog ==="
Write-Host "ScriptDir: $ScriptDir"
Write-Host "PsPath:    $PsPath"

if (-not (Test-Path $PsPath)) {
    Write-Host "ERROR: $PsPath not found. Aborting."
    exit 1
}

Write-Host "Checking if task '$TaskName' already exists ..."
try {
    schtasks.exe /Query /TN $TaskName 2>$null | Out-Null
    $exists = $true
} catch {
    $exists = $false
}

if ($exists) {
    Write-Host "Task '$TaskName' exists. Removing ..."
    schtasks.exe /Delete /TN $TaskName /F | Out-Null
}

$taskCmd = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PsPath`""
Write-Host "Task command: $taskCmd"

Write-Host "Creating scheduled task '$TaskName' (every 5 minutes) ..."
schtasks.exe /Create `
    /SC MINUTE `
    /MO 5 `
    /TN $TaskName `
    /TR $taskCmd `
    /F `
    /RL LIMITED `
    /RU "$env:USERNAME" | Out-Null

Write-Host "Scheduled task '$TaskName' created successfully."
Write-Host "Verifying task '$TaskName' ..."
schtasks.exe /Query /TN $TaskName

Write-Host "=== Jarvis-InstallWatchdog: DONE ==="
