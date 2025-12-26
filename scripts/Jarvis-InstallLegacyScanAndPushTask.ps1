# FILE: F:\AION-ZERO\scripts\Jarvis-InstallLegacyScanAndPushTask.ps1
# Purpose: Install a daily scheduled task that runs:
#   F:\AION-ZERO\scripts\Jarvis-RunLegacyScanAndPush.ps1

param(
    [string]$TaskName   = "Jarvis-LegacyScanAndPush-Daily",
    [string]$ScriptPath = "F:\AION-ZERO\scripts\Jarvis-RunLegacyScanAndPush.ps1",
    [string]$StartTime  = "02:30"   # HH:mm, 24-hour format
)

$ErrorActionPreference = "Stop"

Write-Host "Configuring scheduled task '$TaskName'"
Write-Host "Script     : $ScriptPath"
Write-Host "Start time : $StartTime"
Write-Host ""

if (-not (Test-Path $ScriptPath)) {
    Write-Error "Script not found: $ScriptPath"
    exit 1
}

# Parse the start time into a DateTime
try {
    $timeParts = $StartTime.Split(":")
    if ($timeParts.Count -ne 2) {
        throw "Invalid time format. Use HH:mm, e.g. 02:30"
    }
    $hour = [int]$timeParts[0]
    $min  = [int]$timeParts[1]
    $atTime = (Get-Date).Date.AddHours($hour).AddMinutes($min)
}
catch {
    Write-Error "Failed to parse StartTime '$StartTime': $($_.Exception.Message)"
    exit 1
}

# Build the action: call PowerShell with our script
$psExe  = "powershell.exe"
$psArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

Write-Host "Action exe : $psExe"
Write-Host "Action args: $psArgs"
Write-Host ""

$action  = New-ScheduledTaskAction -Execute $psExe -Argument $psArgs
$trigger = New-ScheduledTaskTrigger -Daily -At $atTime

# Settings (optional but good defaults)
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable

$userId = "$($env:USERDOMAIN)\$($env:USERNAME)"
Write-Host "User       : $userId"
Write-Host ""

# Disable old scan-only task if it exists
$oldTaskName = "Jarvis-LegacyScan-Daily"
$oldTask = Get-ScheduledTask -TaskName $oldTaskName -ErrorAction SilentlyContinue
if ($oldTask) {
    Write-Host "Disabling old task '$oldTaskName'..."
    Disable-ScheduledTask -TaskName $oldTaskName -ErrorAction SilentlyContinue
}

# Create or update the new task
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Task '$TaskName' exists. Updating definition..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
} else {
    Write-Host "Task '$TaskName' does not exist. Creating..."
}

# IMPORTANT: use Action/Trigger/User, not InputObject
Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -User $userId `
    -RunLevel Highest `
    -Force

Write-Host "Task '$TaskName' is configured to run daily at $StartTime."
