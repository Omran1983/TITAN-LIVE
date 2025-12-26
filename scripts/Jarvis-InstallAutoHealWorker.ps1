# Jarvis-InstallAutoHealWorker.ps1
# Creates (or refreshes) the scheduled task 'Jarvis-AutoHealWorker'
# which runs Jarvis-AutoHealWorker.ps1 on a 5-minute schedule.

param(
    [string]$TaskName = "Jarvis-AutoHealWorker"
)

Write-Host "=== Jarvis-InstallAutoHealWorker ==="

# ---- Resolve paths ----
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkerPath = Join-Path $ScriptDir "Jarvis-AutoHealWorker.ps1"

Write-Host "ScriptDir:  $ScriptDir"
Write-Host "WorkerPath: $WorkerPath"

if (-not (Test-Path $WorkerPath)) {
    Write-Error "Worker script not found at $WorkerPath. Create Jarvis-AutoHealWorker.ps1 first."
    exit 1
}

# ---- Check if task already exists (without throwing) ----
Write-Host "Checking if task '$TaskName' already exists ..."

$oldPreference = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"

schtasks.exe /Query /TN $TaskName > $null 2> $null
$taskExists = ($LASTEXITCODE -eq 0)

$ErrorActionPreference = $oldPreference

if ($taskExists) {
    Write-Host "Task '$TaskName' exists. Removing ..."
    schtasks.exe /Delete /TN $TaskName /F > $null 2> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to delete existing task '$TaskName'. ExitCode=$LASTEXITCODE"
        exit 1
    }
} else {
    Write-Host "Task '$TaskName' does not exist. Nothing to delete."
}

# ---- Define the PowerShell command that the task will run ----
$TaskCommand = 'powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}"' -f $WorkerPath
Write-Host "Task command: $TaskCommand"

# ---- Create the scheduled task (every 5 minutes, highest privileges) ----
Write-Host "Creating scheduled task '$TaskName' (every 5 minutes) ..."

schtasks.exe /Create `
    /TN $TaskName `
    /TR $TaskCommand `
    /SC MINUTE `
    /MO 5 `
    /RL HIGHEST `
    /F

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create scheduled task '$TaskName'. ExitCode=$LASTEXITCODE"
    Write-Host "If you see 'Access is denied' or 'requires elevation', run this PowerShell window AS ADMIN."
    exit 1
}

Write-Host "Scheduled task '$TaskName' created successfully."

# ---- Verify the task now exists ----
Write-Host "Verifying task '$TaskName' ..."
schtasks.exe /Query /TN $TaskName

if ($LASTEXITCODE -ne 0) {
    Write-Error "Task '$TaskName' was not found right after creation. Something is wrong."
    exit 1
}

Write-Host "=== Jarvis-InstallAutoHealWorker: DONE ==="
