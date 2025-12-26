$ErrorActionPreference = "Stop"

$workerRoot = "F:\EduConnect\cloud\hq-lite-worker"

if (-not (Test-Path $workerRoot)) {
    Write-Host "EduConnect Worker root not found: $workerRoot" -ForegroundColor Red
    exit 1
}

Push-Location $workerRoot
try {
    if (Get-Command wrangler -ErrorAction SilentlyContinue) {
        Write-Host "Using 'wrangler deploy'..." -ForegroundColor Cyan
        wrangler deploy
    } else {
        Write-Host "Using 'npx wrangler deploy'..." -ForegroundColor Cyan
        npx wrangler deploy
    }
} finally {
    Pop-Location
}
