$ErrorActionPreference = "Stop"

$TaskName = "AION-ZERO Daily Reminder"
$ScriptPath = "F:\AION-ZERO\start.ps1"
$Time = "10:00am"

Write-Host "Setting up Daily Reminder at $Time..." -ForegroundColor Cyan

$Action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoExit -File `"$ScriptPath`""
$Trigger = New-ScheduledTaskTrigger -Daily -At $Time

# Remove if exists
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Register
Try {
    Register-ScheduledTask -Action $Action -Trigger $Trigger -TaskName $TaskName -Description "Daily Dua"
    Write-Host "SUCCESS: Task registered." -ForegroundColor Green
}
Catch {
    Write-Warning "Failed to register task. Run as Administrator."
    Write-Error $_
}
