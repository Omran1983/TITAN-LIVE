$ErrorActionPreference = "Stop"

$baseUrl = "https://educonnect-hq-lite.dubsy1983-51e.workers.dev"
$url     = "$baseUrl/status"

Write-Host "Requesting $url" -ForegroundColor Cyan

try {
    $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30
    Write-Host "Status code: $($resp.StatusCode)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Body:" -ForegroundColor Yellow
    $resp.Content
} catch {
    Write-Host "Request failed: $($_.Exception.Message)" -ForegroundColor Red
}
