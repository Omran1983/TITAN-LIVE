# Jarvis-InstallHealthReflexRules.ps1
# Uses schtasks.exe to install a scheduled task that runs Jarvis-HealthReflexRules.ps1 every 5 minutes.

Write-Host "=== Jarvis-InstallHealthReflexRules ==="

# Resolve script directory and worker path
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir
$workerPath = Join-Path $scriptDir "Jarvis-HealthReflexRules.ps1"

Write-Host "ScriptDir:  $scriptDir"
Write-Host "WorkerPath: $workerPath"

$taskName = "Jarvis-HealthReflexRules"

# 1) Delete any existing task
Write-Host "Removing any existing task '$taskName' ..."
try {
    schtasks.exe /Delete /TN "$taskName" /F 2>$null | Out-Null
} catch {
    Write-Host "No existing task or delete failed (ignored)."
}

# 2) Create the new task: every 5 minutes, hidden PowerShell
$taskCmd = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$workerPath`""

Write-Host "Creating scheduled task '$taskName' to run every 5 minutes ..."
$createResult = schtasks.exe /Create `
    /TN "$taskName" `
    /SC MINUTE `
    /MO 5 `
    /TR "$taskCmd" `
    /RL HIGHEST `
    /F

Write-Host $createResult
Write-Host "Scheduled task '$taskName' created (if no ERROR is shown above)."
