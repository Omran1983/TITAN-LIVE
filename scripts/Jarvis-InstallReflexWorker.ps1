# Jarvis-InstallReflexWorker.ps1
# Uses schtasks.exe to run Jarvis-ReflexWorker.ps1 at user logon.

Write-Host "=== Jarvis-InstallReflexWorker ==="

# Resolve script directory and worker path
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir
$workerPath = Join-Path $scriptDir "Jarvis-ReflexWorker.ps1"

Write-Host "ScriptDir:  $scriptDir"
Write-Host "WorkerPath: $workerPath"

$taskName = "Jarvis-ReflexWorker"

# 1) Delete any existing task
Write-Host "Removing any existing task '$taskName' ..."
try {
    schtasks.exe /Delete /TN "$taskName" /F 2>$null | Out-Null
} catch {
    Write-Host "No existing task or delete failed (ignored)."
}

# 2) Create the new task: run at logon, hidden PowerShell
$taskCmd = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$workerPath`""

Write-Host "Creating scheduled task '$taskName' (run at logon) ..."
$createResult = schtasks.exe /Create `
    /TN "$taskName" `
    /SC ONLOGON `
    /TR "$taskCmd" `
    /RL HIGHEST `
    /F

Write-Host $createResult
Write-Host "Scheduled task '$taskName' created (if no ERROR is shown above)."
