$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=== Jarvis - Start Core Agents (Option C) ===" -ForegroundColor Cyan
Write-Host ""

$base = "F:\AION-ZERO\scripts"
$psExe = "powershell.exe"

$agents = @(
    "Jarvis-CodeAgent-Loop.ps1",
    "Jarvis-RunAutoSql.ps1",
    "Jarvis-NotifyWorker.ps1",
    "Jarvis-ReflexWorker.ps1",
    "Jarvis-Watcher.ps1",
    "Jarvis-AutoHealAgent.ps1"
)

foreach ($file in $agents) {
    $path = Join-Path $base $file

    if (-not (Test-Path $path)) {
        Write-Warning "Skipping $file - not found at $path"
    }
    else {
        Write-Host "Starting $file in background ..." -ForegroundColor Yellow
        Start-Process -FilePath $psExe -ArgumentList "-NoProfile","-WindowStyle","Hidden","-ExecutionPolicy","Bypass","-File",$path
    }
}

Write-Host ""
Write-Host "All available core agents launched in background." -ForegroundColor Green
