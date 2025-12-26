# Run the actual dump
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "F:\AION-ZERO\scripts\Jarvis-DbDump.ps1" |
    Out-File -Append "F:\AION-ZERO\logs\DbDump-Autobackup.log"

# Schedule this runner again after 6 hours
$nextRun = (Get-Date).AddHours(6)

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"`"F:\AION-ZERO\scripts\Jarvis-DbDump-Runner.ps1`"`""

$trigger = New-ScheduledTaskTrigger -Once -At $nextRun

Register-ScheduledTask -TaskName "Jarvis-DbDump" -Action $action -Trigger $trigger -RunLevel Limited -Force
