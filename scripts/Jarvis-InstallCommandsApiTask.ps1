$taskName = "Jarvis-CommandsApi"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$wrapperPath = Join-Path $scriptDir "Jarvis-CommandsApi-Task.ps1"

Write-Host "=== Jarvis-InstallCommandsApiTask ==="
Write-Host "ScriptDir:  $scriptDir"
Write-Host "Wrapper:    $wrapperPath"

if (-not (Test-Path $wrapperPath)) {
    Write-Error "Wrapper script not found at $wrapperPath"
    exit 1
}

Write-Host "Removing any existing task '$taskName' ..."
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

# Action: run the wrapper
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$wrapperPath`""

# Trigger: at startup
$trigger = New-ScheduledTaskTrigger -AtStartup

# Optional: run under current user with highest privileges
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

Write-Host "Registering scheduled task '$taskName' ..."
Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Description "Jarvis Commands API (wrapper -> Jarvis-CommandsApi.ps1)"

Write-Host "=== Done: Jarvis-InstallCommandsApiTask ==="
