$ErrorActionPreference = "Stop"

Write-Host "Clearing CLOUDFLARE_API_TOKEN environment variables (Process/User/Machine)..." -ForegroundColor Yellow

try {
    [Environment]::SetEnvironmentVariable("CLOUDFLARE_API_TOKEN", $null, "Process")
    [Environment]::SetEnvironmentVariable("CLOUDFLARE_API_TOKEN", $null, "User")
} catch {}

try {
    # May fail if not admin – ignore
    [Environment]::SetEnvironmentVariable("CLOUDFLARE_API_TOKEN", $null, "Machine")
} catch {}

Write-Host "Launching 'wrangler login' (this will open a browser; complete the login)..." -ForegroundColor Cyan
wrangler login

Write-Host "Checking whoami..." -ForegroundColor Cyan
wrangler whoami

Write-Host "Running AZ-Deploy-EduConnectWorker.ps1..." -ForegroundColor Cyan
$deployScript = "F:\AION-ZERO\scripts\AZ-Deploy-EduConnectWorker.ps1"
if (Test-Path $deployScript) {
    & $deployScript
} else {
    Write-Host "Deploy script not found at $deployScript" -ForegroundColor Red
    exit 1
}

Write-Host "Running Test-EduConnectStatus.ps1..." -ForegroundColor Cyan
$testScript = "F:\AION-ZERO\scripts\Test-EduConnectStatus.ps1"
if (Test-Path $testScript) {
    & $testScript
} else {
    Write-Host "Test script not found at $testScript" -ForegroundColor Red
}
