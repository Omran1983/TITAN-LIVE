Write-Host "🛑 Stopping Titan Glass Citadel..." -ForegroundColor Red

# 1. Kill Python Backend (Port 5000)
$port5000 = Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue
if ($port5000) {
    Write-Host "   found python server on port 5000 (PID: $($port5000.OwningProcess)). Killing..." -ForegroundColor Yellow
    Stop-Process -Id $port5000.OwningProcess -Force
    Write-Host "   ✅ Backend Stopped." -ForegroundColor Green
}
else {
    Write-Host "   ℹ️  Backend (Port 5000) not found running." -ForegroundColor Gray
}

# 2. Kill Node Frontend (via port 5173 lookup or overly broad kill)
# Safer to just look for the 'cmd' hosting npm if possible, or just tell user.
# Attempting to kill by port 5173 check
$port5173 = Get-NetTCPConnection -LocalPort 5173 -ErrorAction SilentlyContinue
if ($port5173) {
    Write-Host "   found process on port 5173 (PID: $($port5173.OwningProcess)). Killing..." -ForegroundColor Yellow
    Stop-Process -Id $port5173.OwningProcess -Force
    Write-Host "   ✅ Frontend Stopped." -ForegroundColor Green
}
else {
    Write-Host "   ℹ️  Frontend (Port 5173) not found." -ForegroundColor Gray
}

Write-Host "`nCleanup Complete."
