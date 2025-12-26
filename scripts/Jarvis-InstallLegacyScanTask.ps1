param(
    [string]$TaskName   = "Jarvis-LegacyScan-Daily",
    [string]$ScriptPath = "F:\AION-ZERO\scripts\Jarvis-LegacyScanAgent.ps1",
    [string]$StartTime  = "02:30"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ScriptPath)) {
    Write-Error "Legacy scan agent script not found: $ScriptPath"
    exit 1
}

$currentUser = "$env:USERDOMAIN\$env:USERNAME"

Write-Host "Configuring scheduled task '$TaskName' for user $currentUser"
Write-Host "Script: $ScriptPath"
Write-Host "Daily start time: $StartTime"

# Trigger: daily at given time
$trigger = New-ScheduledTaskTrigger -Daily -At $StartTime

# Build a single command-line string for powershell.exe
$argString = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

# Action: run PowerShell with our script
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument $argString `
    -WorkingDirectory "F:\AION-ZERO\scripts"

# Settings: don't stop on battery changes
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries

# Create or update the task
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Write-Host "Task '$TaskName' already exists. Updating..."
    $task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings
    Register-ScheduledTask -TaskName $TaskName -InputObject $task -User $currentUser -Force | Out-Null
} else {
    Write-Host "Task '$TaskName' does not exist. Creating..."
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -User $currentUser | Out-Null
}

Write-Host "Task '$TaskName' is configured."
