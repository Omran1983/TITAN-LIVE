
# ====================== JARVIS AUTOSTART SETUP ======================
$TaskName1 = "Jarvis-Watchdog"
$TaskName2 = "Jarvis-Journal"

$Script1 = "F:\Jarvis\Jarvis-Watchdog.ps1"
$Script2 = "F:\Jarvis\Jarvis-Journal.ps1"

# Create actions
$Action1 = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$Script1`""
$Action2 = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$Script2`""

# Run at user logon
$Trigger = New-ScheduledTaskTrigger -AtLogOn

# Create tasks
Register-ScheduledTask -TaskName $TaskName1 -Trigger $Trigger -Action $Action1 -RunLevel Highest -Force
Register-ScheduledTask -TaskName $TaskName2 -Trigger $Trigger -Action $Action2 -RunLevel Highest -Force

Write-Host "`n✅ JARVIS Watchdog and Journal are now set to run at logon."
