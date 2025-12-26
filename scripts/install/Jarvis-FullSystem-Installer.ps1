<# 
 Jarvis-FullSystem-Installer.ps1
 Option C – Core System Installer

 What it does:
 1) Verifies base folders for Jarvis/AION-ZERO.
 2) Ensures standard subfolders exist (workers, supervisors, patch_engine, health, install).
 3) Runs core wiring scripts:
      - Jarvis-InstallCoreAutomation.ps1  (register scheduled tasks)
      - Jarvis-CreateHealthTable.ps1      (ensure health table exists)
      - Jarvis-StartCoreAgents.ps1        (start core loops now)
 4) Prints a summary of what is ready and what is missing.
#>

param(
    [string] $RootPath = "F:\AION-ZERO"
)

Write-Host "=== Jarvis - Full System Installer (Option C v1) ===" -ForegroundColor Cyan
Write-Host "RootPath = $RootPath" -ForegroundColor DarkGray

# ------------------------------------------------------------------------------
# 1) Basic checks
# ------------------------------------------------------------------------------

if (-not (Test-Path $RootPath)) {
    Write-Host "ERROR: RootPath '$RootPath' does not exist. Adjust the script or create it first." -ForegroundColor Red
    exit 1
}

$scriptDir = Join-Path $RootPath "scripts"
if (-not (Test-Path $scriptDir)) {
    Write-Host "ERROR: Scripts folder '$scriptDir' does not exist." -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------------------------
# 2) Ensure standard subfolders exist
# ------------------------------------------------------------------------------

$subFolders = @(
    "workers",
    "supervisors",
    "patch_engine",
    "health",
    "install",
    "tmp",
    "shared"
)

Write-Host ""
Write-Host "-> Ensuring standard subfolders under $scriptDir ..." -ForegroundColor DarkGray

foreach ($sf in $subFolders) {
    $full = Join-Path $scriptDir $sf
    if (-not (Test-Path $full)) {
        New-Item -ItemType Directory -Path $full | Out-Null
        Write-Host "  + Created: $full" -ForegroundColor Green
    }
    else {
        Write-Host "  = Exists:  $full" -ForegroundColor DarkGray
    }
}

# ------------------------------------------------------------------------------
# 3) Core script presence check
# ------------------------------------------------------------------------------

$coreScripts = @(
    "Jarvis-InstallCoreAutomation.ps1",
    "Jarvis-StartCoreAgents.ps1",
    "Jarvis-CreateHealthTable.ps1",
    "Show-AgentSummary.ps1"
)

Write-Host ""
Write-Host "-> Checking core scripts in $scriptDir ..." -ForegroundColor DarkGray

$missing = @()

foreach ($name in $coreScripts) {
    $path = Join-Path $scriptDir $name
    if (-not (Test-Path $path)) {
        Write-Host "  !! MISSING: $name" -ForegroundColor Yellow
        $missing += $name
    }
    else {
        Write-Host "  OK: $name" -ForegroundColor Green
    }
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "WARNING: Some core scripts are missing. Installer will skip those steps." -ForegroundColor Yellow
}

# ------------------------------------------------------------------------------
# 4) Load environment
# ------------------------------------------------------------------------------

$loadEnv = Join-Path $scriptDir "Jarvis-LoadEnv.ps1"
if (Test-Path $loadEnv) {
    Write-Host ""
    Write-Host "-> Loading environment from Jarvis-LoadEnv.ps1 ..." -ForegroundColor DarkGray
    & $loadEnv
}
else {
    Write-Host ""
    Write-Host "WARNING: Jarvis-LoadEnv.ps1 not found, continuing without env bootstrap." -ForegroundColor Yellow
}

# ------------------------------------------------------------------------------
# 5) Run Jarvis-InstallCoreAutomation.ps1 (register tasks)
# ------------------------------------------------------------------------------

$installCore = Join-Path $scriptDir "Jarvis-InstallCoreAutomation.ps1"
if (Test-Path $installCore) {
    Write-Host ""
    Write-Host "-> Running Jarvis-InstallCoreAutomation.ps1 (register core scheduled tasks) ..." -ForegroundColor DarkGray
    & powershell -NoProfile -ExecutionPolicy Bypass -File $installCore
}
else {
    Write-Host ""
    Write-Host "SKIP: Jarvis-InstallCoreAutomation.ps1 not found." -ForegroundColor Yellow
}

# ------------------------------------------------------------------------------
# 6) Run Jarvis-CreateHealthTable.ps1 (ensure az_health_snapshots table)
# ------------------------------------------------------------------------------

$healthTable = Join-Path $scriptDir "Jarvis-CreateHealthTable.ps1"
if (Test-Path $healthTable) {
    Write-Host ""
    Write-Host "-> Running Jarvis-CreateHealthTable.ps1 (ensure health table exists) ..." -ForegroundColor DarkGray
    & powershell -NoProfile -ExecutionPolicy Bypass -File $healthTable
}
else {
    Write-Host ""
    Write-Host "SKIP: Jarvis-CreateHealthTable.ps1 not found." -ForegroundColor Yellow
}

# ------------------------------------------------------------------------------
# 7) Run Jarvis-StartCoreAgents.ps1 (start loops now)
# ------------------------------------------------------------------------------

$startCore = Join-Path $scriptDir "Jarvis-StartCoreAgents.ps1"
if (Test-Path $startCore) {
    Write-Host ""
    Write-Host "-> Running Jarvis-StartCoreAgents.ps1 (start core agents in background) ..." -ForegroundColor DarkGray
    & powershell -NoProfile -ExecutionPolicy Bypass -File $startCore
}
else {
    Write-Host ""
    Write-Host "SKIP: Jarvis-StartCoreAgents.ps1 not found." -ForegroundColor Yellow
}

# ------------------------------------------------------------------------------
# 8) Show quick health snapshot if available
# ------------------------------------------------------------------------------

$agentSummary = Join-Path $scriptDir "Show-AgentSummary.ps1"
if (Test-Path $agentSummary) {
    Write-Host ""
    Write-Host "-> Running Show-AgentSummary.ps1 (quick health check) ..." -ForegroundColor DarkGray
    & powershell -NoProfile -ExecutionPolicy Bypass -File $agentSummary
}
else {
    Write-Host ""
    Write-Host "SKIP: Show-AgentSummary.ps1 not found." -ForegroundColor Yellow
}

# ------------------------------------------------------------------------------
# 9) Final summary
# ------------------------------------------------------------------------------

Write-Host ""
Write-Host "=== Option C v1 Installer Finished ===" -ForegroundColor Cyan

if ($missing.Count -gt 0) {
    Write-Host "Some core scripts were missing:" -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
    Write-Host "System is partially wired. Fix above items for full coverage." -ForegroundColor Yellow
}
else {
    Write-Host "All core scripts found and invoked successfully." -ForegroundColor Green
    Write-Host "Jarvis core automation + health wiring is now installed." -ForegroundColor Green
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor DarkGray
Write-Host " - Confirm scheduled tasks with:  schtasks /Query /FO TABLE | findstr /I \"Jarvis-\"" -ForegroundColor DarkGray
Write-Host " - Confirm health snapshot with: F:\AION-ZERO\scripts\Show-AgentSummary.ps1" -ForegroundColor DarkGray
