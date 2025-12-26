param(
    [string]$LogPath = "F:\Jarvis\logs\reachx-healthcheck.log"
)

$ErrorActionPreference = "SilentlyContinue"

if (-not (Test-Path $LogPath)) {
    Write-Host "ReachX: UNKNOWN (log file not found at $LogPath)" -ForegroundColor Yellow
    return
}

try {
    # Get the last line in the log that has ReachX-HealthCheck
    $match = Select-String -Path $LogPath -Pattern '\| ReachX-HealthCheck \|' | Select-Object -Last 1

    if (-not $match) {
        Write-Host "ReachX: UNKNOWN (no entries found in log)" -ForegroundColor Yellow
        return
    }

    $line  = $match.Line
    $parts = $line -split '\|'

    if ($parts.Count -lt 4) {
        Write-Host "ReachX: UNKNOWN (log line malformed)" -ForegroundColor Yellow
        Write-Host $line
        return
    }

    $timestamp = $parts[0].Trim()
    # $parts[1] is "ReachX-HealthCheck"
    $level     = $parts[2].Trim()
    $message   = $parts[3].Trim()

    $levelUpper = $level.ToUpperInvariant()

    switch ($levelUpper) {
        'OK' {
            Write-Host "ReachX: OK" -ForegroundColor Green
            Write-Host "  Last check : $timestamp" -ForegroundColor DarkGray
            Write-Host "  Message    : $message"   -ForegroundColor DarkGray
        }
        'ERROR' {
            Write-Host "ReachX: ERROR" -ForegroundColor Red
            Write-Host "  Last check : $timestamp" -ForegroundColor DarkGray
            Write-Host "  Message    : $message"   -ForegroundColor DarkGray
        }
        default {
            Write-Host "ReachX: $levelUpper" -ForegroundColor Yellow
            Write-Host "  Last check : $timestamp" -ForegroundColor DarkGray
            Write-Host "  Message    : $message"   -ForegroundColor DarkGray
        }
    }

    # Optional: machine-readable line if you chain this from other scripts
    Write-Host "ReachXStatus=$levelUpper" -ForegroundColor DarkGray
}
catch {
    Write-Host "ReachX: UNKNOWN (exception while reading log)" -ForegroundColor Yellow
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor DarkGray
}
