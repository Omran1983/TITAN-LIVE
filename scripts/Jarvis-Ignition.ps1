
# JARVIS IGNITION PROTOCOL
# Fires all subsystems.

Write-Host ">>> AION-ZERO IGNITION SEQUENCE INITIATED <<<" -ForegroundColor Cyan


# 0. THE NERVOUS SYSTEM (Commands API) - CRITICAL
Write-Host "Starting System Nervous System (Commands API)..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-File", "F:\AION-ZERO\scripts\Jarvis-CommandsApi.ps1" -WindowStyle Hidden
Start-Sleep -Seconds 2

# 1. THE HEART (Watchdog)
Write-Host "Starting System Heart (Watchdog)..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-File", "F:\AION-ZERO\scripts\Jarvis-Watchdog.ps1" -WindowStyle Normal

# 2. THE MEMORY (Graph Builder)
Write-Host "Starting System Memory (Graph Builder)..." -ForegroundColor Magenta
Start-Process powershell -ArgumentList "-NoExit", "-File", "F:\AION-ZERO\scripts\Jarvis-GraphBuilderWorker.ps1" -WindowStyle Hidden

# 4. THE MUSCLES (Core Agents Mesh)
Write-Host "Starting System Muscles (Core Agents)..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "F:\AION-ZERO\scripts\Jarvis-StartCoreAgents.ps1" -WindowStyle Hidden

Write-Host ">>> IGNITION COMPLETE. SYSTEMS COMING ONLINE. <<<" -ForegroundColor Cyan
Write-Host "Monitor Status in Citadel Dashboard."
Start-Sleep -Seconds 5
