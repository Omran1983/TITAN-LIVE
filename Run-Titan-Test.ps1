Write-Host "=== TITAN HEALTH TEST ===" -ForegroundColor Cyan

# 1. Trigger the Governor to create a new mission entry
Write-Host "1. Triggering 'Uptime Safety Check' (Mission #2) to generate data..." -ForegroundColor Yellow
$governorPath = "f:\AION-ZERO\titan_governor.py"
python $governorPath 2

# 2. Instructions for the User
Write-Host "`n2. Starting Viewers:" -ForegroundColor Cyan
Write-Host "   [Backend] Open a new terminal and run: python f:\AION-ZERO\titan_server.py"
Write-Host "   [Frontend] Open 'f:\AION-ZERO\az-control-center' in terminal and run: npm run dev"
Write-Host "`n   Then navigate to: http://localhost:5173/health"
