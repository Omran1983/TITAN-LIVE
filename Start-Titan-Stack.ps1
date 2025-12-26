Write-Host "🚀 Launching Titan Glass Citadel..." -ForegroundColor Cyan

# 1. Backend
Write-Host "   [1/2] Starting Python Backend (Port 5000)..." -ForegroundColor Yellow
Start-Process -FilePath "python" -ArgumentList "f:\AION-ZERO\titan_server.py" -WorkingDirectory "f:\AION-ZERO" -WindowStyle Normal

# 2. Frontend
Write-Host "   [2/2] Starting Vite Frontend (Port 5173)..." -ForegroundColor Yellow
# Using cmd /c start to ensure it stays open/visible
Start-Process -FilePath "cmd" -ArgumentList "/c cd /d f:\AION-ZERO\az-control-center && npm run dev" -WindowStyle Normal

Write-Host "`n✅ Processes Launched. Waiting 5s for boot..." -ForegroundColor Green
Start-Sleep -Seconds 5

Write-Host "`n🌐 Opening Dashboard..."
Start-Process "http://localhost:5173/health"
