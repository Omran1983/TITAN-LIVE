param(
    [string]$Project     = "AION-ZERO",
    [string]$TaskName    = "Jarvis-RefreshEvidence",
    [string]$RunTime     = "02:30"   # HH:mm 24h format
)

Write-Host "=== Jarvis-InstallRefreshEvidenceTask ==="

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ScriptDir

Write-Host "[InstallTask] ScriptDir = $ScriptDir"
Write-Host "[InstallTask] RootDir   = $RootDir"

# Build the PowerShell command
$scriptPath = Join-Path $ScriptDir "Jarvis-RefreshEvidence.ps1"
if (-not (Test-Path $scriptPath)) {
    Write-Host "[InstallTask] ERROR: Jarvis-RefreshEvidence.ps1 not found at $scriptPath"
    exit 1
}

$psArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Project `"$Project`""

Write-Host "[InstallTask] Using PowerShell args: $psArgs"

# Parse time
try {
    $time = [DateTime]::ParseExact($RunTime, "HH:mm", $null)
}
catch {
    Write-Host "[InstallTask] ERROR: Invalid RunTime format. Use HH:mm (e.g. 02:30)"
    exit 1
}

# Remove existing task if present
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Write-Host "[InstallTask] Removing existing task '$TaskName'..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

$action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $psArgs
$trigger = New-ScheduledTaskTrigger -Daily -At $time.TimeOfDay

Write-Host "[InstallTask] Registering task '$TaskName' to run daily at $RunTime..."

try {
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Description "Nightly refresh of Jarvis evidence cards." -RunLevel Highest | Out-Null
    Write-Host "[InstallTask] Task '$TaskName' registered successfully."
}
catch {
    Write-Host "[InstallTask] ERROR: Failed to register scheduled task."
    Write-Host "[InstallTask] Exception: $($_.Exception.Message)"
    exit 1
}

Write-Host "=== Jarvis-InstallRefreshEvidenceTask done ==="
