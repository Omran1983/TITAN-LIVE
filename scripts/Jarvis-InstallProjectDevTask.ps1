# FILE: F:\AION-ZERO\scripts\Jarvis-InstallProjectDevTask.ps1
# Purpose: Install a daily scheduled task that runs:
#   Jarvis-RunProjectDev.ps1 -ProjectName "<Name>"

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,

    [string]$TaskNamePrefix = "Jarvis-ProjectDev-",

    # 24h HH:mm
    [string]$StartTime = "03:00"
)

$ErrorActionPreference = "Stop"

$taskName = "$TaskNamePrefix$ProjectName"
$scriptPath = "F:\AION-ZERO\scripts\Jarvis-RunProjectDev.ps1"

Write-Host "Configuring scheduled task '$taskName'"
Write-Host "Project    : $ProjectName"
Write-Host "Script     : $scriptPath"
Write-Host "Start time : $StartTime"
Write-Host ""

if (-not (Test-Path $scriptPath)) {
    Write-Error "Script not found: $scriptPath"
    exit 1
}

# Parse time
try {
    $timeParts = $StartTime.Split(":")
    if ($timeParts.Count -ne 2) {
        throw "Invalid time format. Use HH:mm, e.g. 03:00"
    }
    $hour = [int]$timeParts[0]
    $min  = [int]$timeParts[1]
    $atTime = (Get-Date).Date.AddHours($hour).AddMinutes($min)
}
catch {
    Write-Error "Failed to parse StartTime '$StartTime': $($_.Exception.Message)"
    exit 1
}

# Build the action
$psExe = "powershell.exe"
$psArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -ProjectName `"$ProjectName`""

Write-Host "Action exe : $psExe"
Write-Host "Action args: $psArgs"
Write-Host ""

$action  = New-ScheduledTaskAction -Execute $psExe -Argument $psArgs
$trigger = New-ScheduledTaskTrigger -Daily -At $atTime
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable

$userId = "$($env:USERDOMAIN)\$($env:USERNAME)"
Write-Host "User       : $userId"
Write-Host ""

$existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Task '$taskName' exists. Updating definition..."
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
} else {
    Write-Host "Task '$taskName' does not exist. Creating..."
}

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -User $userId `
    -RunLevel Highest `
    -Force

Write-Host "Task '$taskName' is configured to run daily at $StartTime."
