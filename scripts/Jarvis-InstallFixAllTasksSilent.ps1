# Jarvis-InstallFixAllTasksSilent.ps1
# Registers a daily hidden task that runs Jarvis-FixAllTasksSilent.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

$taskName   = "Jarvis-FixAllTasksSilent-Daily"
$psPath     = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$scriptPath = Join-Path $ScriptDir "Jarvis-FixAllTasksSilent.ps1"

if (-not (Test-Path $scriptPath)) {
    Write-Error "Expected script not found: $scriptPath"
    exit 1
}

Write-Host "Installing scheduled task '$taskName' to run $scriptPath daily (hidden)..."

# Remove any old version
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

# Action: run PowerShell, hidden, calling Jarvis-FixAllTasksSilent.ps1
$argument = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
$action   = New-ScheduledTaskAction -Execute $psPath -Argument $argument

# Trigger: daily at 02:20 local time (change if you want)
$runTime = [DateTime]::Today.AddHours(2).AddMinutes(20)  # 02:20
$trigger = New-ScheduledTaskTrigger -Daily -At $runTime

# Register task with highest privileges
Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Description "Runs Jarvis-FixAllTasksSilent.ps1 daily (hidden) to keep Jarvis tasks clean" `
    -RunLevel Highest | Out-Null

Write-Host "Task '$taskName' registered."
Write-Host "Next run: $((Get-ScheduledTask -TaskName $taskName | Get-ScheduledTaskInfo).NextRunTime)"
