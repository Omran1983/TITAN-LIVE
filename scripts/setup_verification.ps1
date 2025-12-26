$ErrorActionPreference = "Stop"

$TaskName = "TITAN Self-Test"
$ScriptPath = "F:\AION-ZERO\core\quality\verify_system.py"
$PythonPath = "python" # Assuming python is in PATH
$Time = "10:05am"

Write-Host "Setting up TITAN Self-Test at $Time..." -ForegroundColor Cyan

# Action: Run python script. We run it via powershell to keep environment clean or cmd.
# cmd /c python ...
$Action = New-ScheduledTaskAction -Execute $PythonPath -Argument "`"$ScriptPath`" --strict"
$Trigger = New-ScheduledTaskTrigger -Daily -At $Time

# Check if exists
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

Try {
    Register-ScheduledTask -Action $Action -Trigger $Trigger -TaskName $TaskName -Description "Daily Tier-1 Verification Run"
    Write-Host "SUCCESS: TITAN Self-Test registered." -ForegroundColor Green
}
Catch {
    Write-Warning "Failed to register task. Run as Administrator."
    Write-Error $_
}
