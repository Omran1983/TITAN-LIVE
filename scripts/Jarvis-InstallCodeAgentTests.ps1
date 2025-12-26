$ErrorActionPreference = 'Stop'

Write-Host "=== Jarvis-InstallCodeAgentTests ==="

$taskName   = "Jarvis-CodeAgentTests"
$scriptPath = "F:\AION-ZERO\scripts\CodeAgent-RunTests.ps1"

if (-not (Test-Path $scriptPath)) {
    throw "CodeAgent test script not found at $scriptPath"
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

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -Daily -At 3:10am
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings | Out-Null

Write-Host "Task '$taskName' installed. It will run daily at 03:10."
