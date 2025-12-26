# FILE: F:\AION-ZERO\scripts\Jarvis-RunLegacyScanAndPush.ps1
# Purpose: One-button pipeline
#   1) Run legacy Python scanner via Jarvis-LegacyScanAgent.ps1
#   2) Push latest scan result to Supabase via Jarvis-PushLegacyScanToSupabase.ps1

$ErrorActionPreference = "Stop"

$baseDir   = "F:\AION-ZERO"
$scriptsDir = Join-Path $baseDir "scripts"

$agentScript = Join-Path $scriptsDir "Jarvis-LegacyScanAgent.ps1"
$pushScript  = Join-Path $scriptsDir "Jarvis-PushLegacyScanToSupabase.ps1"

Write-Host "=== Jarvis Legacy Scan + Push ==="
Write-Host "BaseDir      : $baseDir"
Write-Host "Agent script : $agentScript"
Write-Host "Push script  : $pushScript"
Write-Host "Timestamp    : $(Get-Date -Format o)"
Write-Host ""

# --- Sanity checks ---

if (-not (Test-Path $agentScript)) {
    Write-Error "Agent script not found: $agentScript"
    exit 1
}
if (-not (Test-Path $pushScript)) {
    Write-Error "Push script not found: $pushScript"
    exit 1
}

# --- Step 1: Run legacy scan agent ---

Write-Host ">> STEP 1: Running Jarvis-LegacyScanAgent.ps1"
try {
    & $agentScript
}
catch {
    Write-Error "Jarvis-LegacyScanAgent.ps1 failed: $($_.Exception.Message)"
    exit 1
}

Write-Host ""
Write-Host "Jarvis-LegacyScanAgent.ps1 completed."
Write-Host ""

# Optional small delay to ensure files flushed (usually not needed, but cheap)
Start-Sleep -Seconds 2

# --- Step 2: Push result to Supabase ---

Write-Host ">> STEP 2: Running Jarvis-PushLegacyScanToSupabase.ps1"
try {
    & $pushScript
}
catch {
    Write-Error "Jarvis-PushLegacyScanToSupabase.ps1 failed: $($_.Exception.Message)"
    exit 1
}

Write-Host ""
Write-Host "=== Legacy scan + Supabase push finished successfully ==="
