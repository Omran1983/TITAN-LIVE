$ErrorActionPreference = 'Stop'

Write-Host "=== Jarvis-InstallRegressionAgent ==="

$taskName   = "Jarvis-RegressionAgent"
$scriptPath = "F:\AION-ZERO\scripts\Jarvis-RegressionAgent.ps1"

if (-not (Test-Path $scriptPath)) {
    throw "Regression agent script not found at $scriptPath"
}

try {
    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "Removing existing task '$taskName' ..."
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
}
catch {
    Write-Warning "Failed to remove existing task (if any): $($_.Exception.Message)"
}

Write-Host "Creating scheduled task '$taskName' ..."

$startTime = (Get-Date).AddMinutes(1)

$trigger = New-ScheduledTaskTrigger `
    -Once `
    -At $startTime `
    -RepetitionInterval (New-TimeSpan -Minutes 10) `
    -RepetitionDuration (New-TimeSpan -Days 365)

$action   = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings | Out-Null

Write-Host "Task '$taskName' installed. It will run every 10 minutes for 365 days."
