# Panic-Stop.ps1
# -----------------------------------------------------------------------------
# GLOBAL KILL SWITCH FOR AION-ZERO / JARVIS
# -----------------------------------------------------------------------------
# Actions:
# 1. Creates F:\AION-ZERO\JARVIS.PANIC.LOCK
# 2. Disables all 'Jarvis-*' Scheduled Tasks
# 3. Kills all 'powershell' and 'python' processes (Blind kill for safety)
#
# RECOVERY:
# - Delete JARVIS.PANIC.LOCK
# - Re-enable Scheduled Tasks manually
# -----------------------------------------------------------------------------

$ErrorActionPreference = "Continue"

Write-Host "!!! INITIATING AION-ZERO PANIC STOP !!!" -ForegroundColor Red
Write-Host "This will kill processes and disable tasks." -ForegroundColor Red

# 1. Create Lockfile
$LockFile = "F:\AION-ZERO\JARVIS.PANIC.LOCK"
try {
    New-Item -Path $LockFile -ItemType File -Force | Out-Null
    Set-Content -Path $LockFile -Value "PANIC STOPPED AT $(Get-Date)"
    Write-Host "[OK] Lockfile created at $LockFile" -ForegroundColor Green
}
catch {
    Write-Warning "[FAIL] Could not create lockfile: $($_.Exception.Message)"
}

# 2. Disable Scheduled Tasks
$tasks = Get-ScheduledTask -TaskName "Jarvis-*" -ErrorAction SilentlyContinue
if ($tasks) {
    foreach ($t in $tasks) {
        try {
            Disable-ScheduledTask -InputObject $t | Out-Null
            Write-Host "[OK] Disabled task: $($t.TaskName)" -ForegroundColor Yellow
        }
        catch {
            Write-Warning "[FAIL] Failed to disable $($t.TaskName): $($_.Exception.Message)"
        }
    }
}
else {
    Write-Host "[INFO] No Jarvis-* tasks found."
}

# 3. Kill Processes
# Note: Broad kill for maximum safety in panic mode.
# We attempt to kill by name.
$procNames = @("powershell", "pwsh", "python")

foreach ($name in $procNames) {
    $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
    foreach ($p in $procs) {
        # Optional: Skip self
        if ($p.Id -eq $PID) { continue }

        try {
            Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
            Write-Host "[KILL] Stopped $name (PID $($p.Id))" -ForegroundColor Red
        }
        catch {
            # Ignore access denied etc
        }
    }
}

Write-Host ""
Write-Host "!!! PANIC STOP COMPLETE !!!" -ForegroundColor Red
Write-Host "To recover:"
Write-Host "1. Delete $LockFile"
Write-Host "2. Enable Scheduled Tasks"
