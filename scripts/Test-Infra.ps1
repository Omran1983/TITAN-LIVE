# F:\AION-ZERO\scripts\Test-Infra.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== AION-ZERO Infra Healthcheck ==="
Write-Host ""

Write-Host ">>> Supabase"
try {
    & "F:\AION-ZERO\scripts\Test-Supabase.ps1"
}
catch {
    Write-Warning ("Supabase healthcheck FAILED: " + $_.Exception.Message)
}
Write-Host ""

Write-Host ">>> Cloudflare"
try {
    & "F:\AION-ZERO\scripts\Test-Cloudflare.ps1"
}
catch {
    Write-Warning ("Cloudflare healthcheck FAILED: " + $_.Exception.Message)
}

Write-Host ""
Write-Host "=== HEALTHCHECK DONE ==="
