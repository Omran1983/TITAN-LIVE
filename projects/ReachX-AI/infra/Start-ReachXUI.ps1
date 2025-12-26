param(
    [string]$LogPath = "F:\Jarvis\logs\reachx-healthcheck.log",
    [string]$DashboardPath = "F:\ReachX-AI\reachx-dashboard-v2.html"
)

$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "=============================" -ForegroundColor DarkGray
Write-Host " REACHX — UI LAUNCH CHECK    " -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor DarkGray

if (-not (Test-Path $LogPath)) {
    Write-Host "ReachX: UNKNOWN (log file not found at $LogPath)" -ForegroundColor Yellow
    Write-Host "UI will NOT be opened." -ForegroundColor Yellow
    return
}

# Get the last ReachX-HealthCheck line
$match = Select-String -Path $LogPath -Pattern '\| ReachX-HealthCheck \|' | Select-Object -Last 1

if (-not $match) {
    Write-Host "ReachX: UNKNOWN (no health entries found in log)" -ForegroundColor Yellow
    Write-Host "UI will NOT be opened." -ForegroundColor Yellow
    return
}

$line  = $match.Line
$parts = $line -split '\|'

if ($parts.Count -lt 4) {
    Write-Host "ReachX: UNKNOWN (malformed log line)" -ForegroundColor Yellow
    Write-Host $line
    Write-Host "UI will NOT be opened." -ForegroundColor Yellow
    return
}

$timestamp = $parts[0].Trim()
$level     = $parts[2].Trim()
$message   = $parts[3].Trim()
$levelUpper = $level.ToUpperInvariant()

Write-Host "Last health check: $timestamp" -ForegroundColor DarkGray
Write-Host "Status          : $levelUpper" -ForegroundColor DarkGray
Write-Host "Message         : $message"    -ForegroundColor DarkGray
Write-Host ""

if ($levelUpper -ne "OK") {
    Write-Host "ReachX is NOT healthy (status = $levelUpper)." -ForegroundColor Red
    Write-Host "Dashboard will NOT be opened. Fix health first." -ForegroundColor Red
    return
}

if (-not (Test-Path $DashboardPath)) {
    Write-Host "ReachX: OK, but dashboard file not found at:" -ForegroundColor Yellow
    Write-Host "  $DashboardPath" -ForegroundColor Yellow
    return
}

Write-Host "ReachX is healthy. Opening dashboard..." -ForegroundColor Green
Start-Process $DashboardPath
