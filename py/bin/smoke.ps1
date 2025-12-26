$ErrorActionPreference = "Stop"
$bin  = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $bin "setup.ps1")
$launcher = Join-Path $bin "launcher.ps1"

Write-Host "Ping (Binance)..." -ForegroundColor Yellow
& powershell -NoLogo -ExecutionPolicy Bypass -File $launcher ping

Write-Host "Cache put/get..." -ForegroundColor Yellow
& powershell -NoLogo -ExecutionPolicy Bypass -File $launcher cache_put foo bar
& powershell -NoLogo -ExecutionPolicy Bypass -File $launcher cache_get foo

Write-Host "Demo courier..." -ForegroundColor Yellow
$root = Split-Path -Parent $bin            # .../py
$venvPy = Join-Path (Join-Path $root "venv") "Scripts\python.exe"
& $venvPy (Join-Path $root "demo_courier.py")

Write-Host "SMOKE OK" -ForegroundColor Green
