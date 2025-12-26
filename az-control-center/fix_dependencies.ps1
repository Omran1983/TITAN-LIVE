
Write-Host "Starting Hard Dependency Reset..." -ForegroundColor Cyan

# 1. Kill Processes
Write-Host "Killing processes..."
Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "python" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "ollama_app_v2" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# 2. Cleanup
$target = "f:\AION-ZERO\az-control-center"
Set-Location $target

if (Test-Path "node_modules") {
    Write-Host "REMOVE node_modules..."
    Remove-Item -Path "node_modules" -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path "package-lock.json") {
    Write-Host "REMOVE package-lock.json..."
    Remove-Item -Path "package-lock.json" -Force -ErrorAction SilentlyContinue
}

# 3. Cache Clean
Write-Host "Cleaning NPM Cache..."
npm cache clean --force

# 4. Install
Write-Host "Installing Dependencies (this may take a minute)..."
npm install --no-audit

# 5. Verify
if (Test-Path "node_modules\lucide-react") {
    Write-Host "SUCCESS: lucide-react found." -ForegroundColor Green
}
else {
    Write-Host "ERROR: lucide-react STILL MISSING." -ForegroundColor Red
}

Write-Host "Done."
