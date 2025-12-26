<#
.SYNOPSIS
    Install or refresh the scheduled task that runs SecOps-RunTests.ps1 daily.

.NOTES
    Place in: F:\AION-ZERO\scripts\Jarvis-InstallSecOpsTests.ps1

    Run once:
      PS> cd F:\AION-ZERO\scripts
      PS> .\Jarvis-InstallSecOpsTests.ps1
#>

$ErrorActionPreference = 'Stop'

Write-Host "=== Jarvis-InstallSecOpsTests ==="

$taskName   = "Jarvis-SecOpsTests"
$scriptPath = "F:\AION-ZERO\scripts\SecOps-RunTests.ps1"

if (-not (Test-Path $scriptPath)) {
    throw "SecOps test script not found at $scriptPath"
}

# Remove existing task if present
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

# Create new action & trigger
Write-Host "Creating scheduled task '$taskName' ..."

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

# Daily at 03:00 Mauritius time (Windows uses local time)
$trigger = New-ScheduledTaskTrigger -Daily -At 3:00am

# Run whether user is logged on or not; no GUI
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings | Out-Null

Write-Host "Task '$taskName' installed. It will run daily at 03:00."
