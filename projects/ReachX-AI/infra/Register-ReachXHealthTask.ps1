param(
    [string]$TaskName = "ReachX-HealthCheck",
    [int]$EveryMinutes = 30
)

$ErrorActionPreference = "Stop"

# Path to the health-check script
$scriptPath = "F:\ReachX-AI\infra\ReachX-HealthCheck.ps1"

if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: Health-check script not found at $scriptPath" -ForegroundColor Red
    return
}

Write-Host "Registering scheduled task '$TaskName' to run every $EveryMinutes minute(s)..." -ForegroundColor Cyan

# Command to run
$action = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

try {
    # Create or overwrite the task
    schtasks /Create `
        /SC MINUTE `
        /MO $EveryMinutes `
        /TN $TaskName `
        /TR $action `
        /F | Out-Host

    Write-Host ""
    Write-Host "Task '$TaskName' registered. Current definition:" -ForegroundColor Green
    schtasks /Query /TN $TaskName /V /FO LIST | Out-Host
    Write-Host ""
    Write-Host "Done. Windows will now run ReachX-HealthCheck.ps1 every $EveryMinutes minute(s)." -ForegroundColor Cyan
}
catch {
    Write-Host "ERROR: Failed to register scheduled task: $($_.Exception.Message)" -ForegroundColor Red
}
