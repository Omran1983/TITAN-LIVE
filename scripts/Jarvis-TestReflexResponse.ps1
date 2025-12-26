# Jarvis-TestReflexResponse.ps1
# -----------------------------------------------------------------------------
# REFLEX ENGINE "CHAOS TEST"
# -----------------------------------------------------------------------------
# PROOF OF SELF-HEALING:
# 1. Deliberately sabotage a component (Stop Jarvis-GraphBuilderWorker).
# 2. Run the Reflex Engine.
# 3. Verify that the Reflex Engine detected and FIXED the sabotage.
# -----------------------------------------------------------------------------

$ErrorActionPreference = "Stop"
$TargetTask = "Jarvis-GraphBuilderWorker"

function Write-Step { param($Msg) Write-Host "[TEST] $Msg" -ForegroundColor Cyan }
function Write-Pass { param($Msg) Write-Host "[PASS] $Msg" -ForegroundColor Green }
function Write-Fail { param($Msg) Write-Host "[FAIL] $Msg" -ForegroundColor Red }

Write-Step "1. SABOTAGE: Stopping $TargetTask..."
Stop-ScheduledTask -TaskName $TargetTask -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$state = (Get-ScheduledTask -TaskName $TargetTask).State
if ($state -eq "Running") {
    Write-Fail "Could not stop task. Test Aborted."
    exit
}
Write-Step "   -> Task is now: $state (Sabotage Successful)"

Write-Step "2. REACTION: Invoking Reflex Engine..."
# Force run the Reflex Engine script directly to see output
powershell -ExecutionPolicy Bypass -File "F:\AION-ZERO\scripts\Jarvis-ReflexEngine.ps1"

Write-Step "3. VERIFICATION: Checking outcome..."
Start-Sleep -Seconds 3

$newState = (Get-ScheduledTask -TaskName $TargetTask).State
if ($newState -eq "Running") {
    Write-Pass "Reflex Engine successfully RESTARTED $TargetTask!"
    Write-Pass "Self-Healing Verified."
}
else {
    Write-Fail "Task is still $newState.  Reflex failed to heal."
}
