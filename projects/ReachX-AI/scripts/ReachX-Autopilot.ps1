Param(
    [string]$ProjectRoot = "F:\ReachX-AI",
    [string]$ScriptsRoot = "F:\ReachX-AI\scripts"
)

$ErrorActionPreference = "Stop"

function Queue-ReachXFixTask {
    param(
        [string]$TaskDescription
    )
    $logPath   = Join-Path $ProjectRoot "reachx-autopilot-queued.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp | $TaskDescription" | Add-Content -Path $logPath
}

while ($true) {
    Write-Host "[ReachX-Autopilot] Running done check..." -ForegroundColor Cyan

    & (Join-Path $ScriptsRoot "ReachX-Done-Check.ps1") -ProjectRoot $ProjectRoot
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        Write-Host "[ReachX-Autopilot] ReachX is COMPLETE (MVP). Sleeping 1800s..." -ForegroundColor Green
        Start-Sleep -Seconds 1800
        continue
    }

    Write-Host "[ReachX-Autopilot] ReachX NOT complete. Queuing fix tasks..." -ForegroundColor Yellow
    Queue-ReachXFixTask -TaskDescription "ReachX not matching SPEC - trigger codegen/patch cycle."

    Start-Sleep -Seconds 60
}
