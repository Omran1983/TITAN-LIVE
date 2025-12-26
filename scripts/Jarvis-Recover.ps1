# Jarvis-Recover.ps1
# -----------------------------------------------------------------------------
# EMERGENCY RECOVERY SYSTEM
# -----------------------------------------------------------------------------
# Unlocks the system after a Panic Stop and restarts all agents.

$ErrorActionPreference = "SilentlyContinue"
$LockFile = "F:\AION-ZERO\JARVIS.PANIC.LOCK"

Write-Host "!!! INITIATING SYSTEM RECOVERY !!!" -ForegroundColor Green

# 1. Remove Lock
if (Test-Path $LockFile) {
    Remove-Item $LockFile -Force
    Write-Host "[OK] Lockfile removed." -ForegroundColor Green
}
else {
    Write-Host "[INFO] No lockfile found." -ForegroundColor Yellow
}

# 2. Enable All Jarvis Tasks
Write-Host "Enabling Scheduled Tasks..."
$Tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "Jarvis-*" }
foreach ($T in $Tasks) {
    Enable-ScheduledTask -TaskName $T.TaskName | Out-Null
    Write-Host "  [ENABLED] $($T.TaskName)" -ForegroundColor Gray
}

# 3. Start Core Agents
Write-Host "Restarting Core Agents..."
$Core = @(
    "Jarvis-CommandsApi",
    "Jarvis-HealthWatchdog", # Corrected Name
    "Jarvis-Reflex",
    "Jarvis-RevenueGen",
    "Jarvis-DocGen"
)

foreach ($C in $Core) {
    Start-ScheduledTask -TaskName $C
    Write-Host "  [STARTED] $C" -ForegroundColor Cyan
}

# 4. Special Handling for GraphBuilder (Re-register if missing)
if (-not (Get-ScheduledTask -TaskName "Jarvis-GraphBuilderWorker")) {
    Write-Host "[FIX] Re-registering Jarvis-GraphBuilderWorker..."
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File F:\AION-ZERO\scripts\Jarvis-GraphBuilderWorker.ps1"
    $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 10)
    Register-ScheduledTask -TaskName "Jarvis-GraphBuilderWorker" -Action $Action -Trigger $Trigger -Force
    Start-ScheduledTask -TaskName "Jarvis-GraphBuilderWorker"
}
else {
    Enable-ScheduledTask -TaskName "Jarvis-GraphBuilderWorker"
    Start-ScheduledTask -TaskName "Jarvis-GraphBuilderWorker"
    Write-Host "  [STARTED] Jarvis-GraphBuilderWorker" -ForegroundColor Cyan
}

Write-Host "!!! SYSTEM ONLINE !!!" -ForegroundColor Green
Write-Host "Verify dashboard at http://localhost:9000"
