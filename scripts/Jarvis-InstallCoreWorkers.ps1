param(
    [string]$Project = "AION-ZERO",
    [int]   $CommandsApiPort = 5052
)

Write-Host "=== Jarvis-InstallCoreWorkers ==="

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir

Write-Host "[CoreWorkers] ScriptDir = $ScriptDir"
Write-Host "[CoreWorkers] RootDir   = $RootDir"

# Helper: safely register a scheduled task for a given script
function Register-JarvisTask {
    param(
        [string]$TaskName,
        [string]$ScriptName,
        [string]$Arguments,
        [TimeSpan]$Interval,
        [switch]$AtStartup,
        [switch]$Daily,
        [string]$DailyTime = "02:30"
    )

    $scriptPath = Join-Path $ScriptDir $ScriptName

    if (-not (Test-Path $scriptPath)) {
        Write-Host "[CoreWorkers] SKIP $TaskName -> script not found: $scriptPath"
        return
    }

    Write-Host "[CoreWorkers] Installing task '$TaskName' for $ScriptName"

    $psArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    if ($Arguments) {
        $psArgs = "$psArgs $Arguments"
    }

    Write-Host "[CoreWorkers]   PowerShell args: $psArgs"

    # Remove existing task if present
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Write-Host "[CoreWorkers]   Removing existing task '$TaskName'..."
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $psArgs
    $triggers = @()

    if ($AtStartup) {
        $triggers += New-ScheduledTaskTrigger -AtStartup
    }

    if ($Daily) {
        # Daily at specific time (DateTime, not TimeSpan)
        $dt = [DateTime]::ParseExact($DailyTime, "HH:mm", $null)
        $triggers += New-ScheduledTaskTrigger -Daily -At $dt
    }

    if ($Interval -ne $null -and $Interval.TotalMinutes -gt 0 -and -not $Daily) {
        # Repeating trigger: start once, then repeat every Interval
        # Duration MUST be finite; Windows doesn't like TimeSpan.MaxValue.
        $start = (Get-Date).AddMinutes(1)
        $repetitionDuration = New-TimeSpan -Days 30  # 30 days is within scheduler limits

        $triggers += New-ScheduledTaskTrigger `
            -Once `
            -At $start `
            -RepetitionInterval $Interval `
            -RepetitionDuration $repetitionDuration
    }

    if ($triggers.Count -eq 0) {
        Write-Host "[CoreWorkers]   ERROR: No trigger configured for $TaskName. Skipping."
        return
    }

    try {
        Register-ScheduledTask `
            -TaskName $TaskName `
            -Action $action `
            -Trigger $triggers `
            -Description "Jarvis worker: $TaskName" `
            -RunLevel Highest | Out-Null

        Write-Host "[CoreWorkers]   Task '$TaskName' registered successfully."
    }
    catch {
        Write-Host "[CoreWorkers]   ERROR: Failed to register '$TaskName': $($_.Exception.Message)"
    }
}

# =======================
# Register core workers
# =======================

# 1) Commands API → run at startup (port = CommandsApiPort)
Register-JarvisTask `
    -TaskName  "Jarvis-CommandsApi" `
    -ScriptName "Jarvis-CommandsApi.ps1" `
    -Arguments "-Port $CommandsApiPort" `
    -Interval ([TimeSpan]::Zero) `
    -AtStartup

# 2) Health snapshot worker → every 5 minutes
Register-JarvisTask `
    -TaskName  "Jarvis-HealthSnapshotWorker" `
    -ScriptName "Jarvis-HealthSnapshotWorker.ps1" `
    -Arguments "" `
    -Interval (New-TimeSpan -Minutes 5)

# 3) Health reflex rules → every 5 minutes
Register-JarvisTask `
    -TaskName  "Jarvis-HealthReflexRules" `
    -ScriptName "Jarvis-HealthReflexRules.ps1" `
    -Arguments "" `
    -Interval (New-TimeSpan -Minutes 5)

# 4) Notify worker → every 1 minute
Register-JarvisTask `
    -TaskName  "Jarvis-NotifyWorker" `
    -ScriptName "Jarvis-NotifyWorker.ps1" `
    -Arguments "" `
    -Interval (New-TimeSpan -Minutes 1)

# 5) Code agent → every 3 minutes (only if script exists)
Register-JarvisTask `
    -TaskName  "Jarvis-CodeAgent" `
    -ScriptName "Jarvis-CodeAgent.ps1" `
    -Arguments "" `
    -Interval (New-TimeSpan -Minutes 3)

# 6) FileOps worker → every 1 minute (only if script exists)
Register-JarvisTask `
    -TaskName  "Jarvis-FileOpsWorker" `
    -ScriptName "Jarvis-FileOpsWorker.ps1" `
    -Arguments "" `
    -Interval (New-TimeSpan -Minutes 1)

# 7) Evidence refresh (nightly @ 02:30) – if script exists
Register-JarvisTask `
    -TaskName  "Jarvis-RefreshEvidence" `
    -ScriptName "Jarvis-RefreshEvidence.ps1" `
    -Arguments "-Project `"$Project`"" `
    -Interval ([TimeSpan]::Zero) `
    -Daily `
    -DailyTime "02:30"

# 8) Heartbeat Beacon (Vital Sign) → every 1 minute
Register-JarvisTask `
    -TaskName  "Jarvis-HeartbeatBeacon" `
    -ScriptName "Jarvis-HeartbeatBeacon.ps1" `
    -Arguments "" `
    -Interval (New-TimeSpan -Minutes 1)

# 9) ReachX RunLoop → every 10 minutes
Register-JarvisTask `
    -TaskName  "Jarvis-RunLoop-reachx" `
    -ScriptName "Jarvis-RunProjectLoop.ps1" `
    -Arguments "-Project reachx" `
    -Interval (New-TimeSpan -Minutes 10)

Write-Host "=== Jarvis-InstallCoreWorkers done ==="
