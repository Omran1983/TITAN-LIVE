Write-Host "=== Jarvis-InstallHealthWorker ===" -ForegroundColor Cyan

# Resolve script folder
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir  = Split-Path -Parent $scriptPath

Write-Host "ScriptDir: $scriptDir" -ForegroundColor DarkGray

# Worker path
$workerPath = Join-Path $scriptDir "Jarvis-HealthSnapshotWorker.ps1"
Write-Host "WorkerPath: $workerPath" -ForegroundColor DarkGray

if (-not (Test-Path $workerPath)) {
    Write-Host "ERROR: Jarvis-HealthSnapshotWorker.ps1 not found at $workerPath" -ForegroundColor Red
    exit 1
}

$taskName = "Jarvis-HealthSnapshotWorker"

Write-Host "Removing any existing task '$taskName' ..." -ForegroundColor DarkGray
schtasks /Delete /TN "$taskName" /F 2>$null | Out-Null

Write-Host "Creating scheduled task '$taskName' to run every 5 minutes..." -ForegroundColor DarkCyan

# This runs the worker hidden, every 5 minutes, under the current user context
$tr = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $workerPath + '"'

schtasks /Create `
    /TN "$taskName" `
    /TR "$tr" `
    /SC MINUTE `
    /MO 5 `
    /F

if ($LASTEXITCODE -eq 0) {
    Write-Host "Scheduled task '$taskName' installed/updated successfully." -ForegroundColor Green
    Write-Host "It will run every 5 minutes under the current user." -ForegroundColor Green
    Write-Host "=== Jarvis-InstallHealthWorker complete ===" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "ERROR: Failed to create scheduled task '$taskName'. ExitCode=$LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
