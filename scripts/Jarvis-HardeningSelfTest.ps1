<# 
    Jarvis-HardeningSelfTest.ps1
    ----------------------------
    Runs a suite of sanity checks over the AION-ZERO "Class A Enterprise" hardening.

    This script is SAFE: 
      - It does NOT kill processes
      - It does NOT trigger Panic-Stop
      - It does NOT modify .env or any code

    Output:
      - Console summary
      - Optional JSON report file (see $ReportPath)
#>

param(
    [string]$ReportPath = "F:\AION-ZERO\reports\hardening_selftest_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
)

$ErrorActionPreference = 'Stop'

# Helper to record test results
$results = @()

function Add-TestResult {
    param(
        [string]$Id,
        [string]$Area,
        [string]$Description,
        [bool]$Passed,
        [string]$Details
    )
    $results += [pscustomobject]@{
        TestId      = $Id
        Area        = $Area
        Description = $Description
        Passed      = $Passed
        Details     = $Details
        Timestamp   = (Get-Date).ToString("s")
    }

    $status = if ($Passed) { "[OK]" } else { "[FAIL]" }
    Write-Host ("{0} {1} - {2}" -f $status, $Id, $Description)
    if (-not $Passed) {
        Write-Host ("       Details: {0}" -f $Details)
    }
}

# --- Test 1: Files existence ---

Add-TestResult -Id "P1-F1" -Area "Phase1" -Description "Panic-Stop.ps1 exists" `
    -Passed (Test-Path "F:\AION-ZERO\scripts\Panic-Stop.ps1") `
    -Details "Expected at F:\AION-ZERO\scripts\Panic-Stop.ps1"

Add-TestResult -Id "P1-F2" -Area "Phase1" -Description "Jarvis-Watchdog.ps1 exists" `
    -Passed (Test-Path "F:\AION-ZERO\scripts\Jarvis-Watchdog.ps1") `
    -Details "Expected at F:\AION-ZERO\scripts\Jarvis-Watchdog.ps1"

Add-TestResult -Id "P1-F3" -Area "Phase1" -Description "Jarvis-CommandsApi.ps1 exists" `
    -Passed (Test-Path "F:\AION-ZERO\scripts\Jarvis-CommandsApi.ps1") `
    -Details "Expected at F:\AION-ZERO\scripts\Jarvis-CommandsApi.ps1"

Add-TestResult -Id "P2-F1" -Area "Phase2" -Description "Jarvis-CodeAgent.ps1 exists" `
    -Passed (Test-Path "F:\AION-ZERO\scripts\Jarvis-CodeAgent.ps1") `
    -Details "Expected at F:\AION-ZERO\scripts\Jarvis-CodeAgent.ps1"

Add-TestResult -Id "P3-F1" -Area "Phase3" -Description "az_ledger.sql present" `
    -Passed (Test-Path "F:\AION-ZERO\sql\az_ledger.sql") `
    -Details "Expected at F:\AION-ZERO\sql\az_ledger.sql"

Add-TestResult -Id "P4-F1" -Area "Phase4" -Description "graph_builder.py exists" `
    -Passed (Test-Path "F:\AION-ZERO\py\graph_builder.py") `
    -Details "Expected at F:\AION-ZERO\py\graph_builder.py"

Add-TestResult -Id "P6-F1" -Area "Phase6" -Description "Citadel backend exists (citadel\main.py)" `
    -Passed (Test-Path "F:\AION-ZERO\citadel\main.py") `
    -Details "Expected at F:\AION-ZERO\citadel\main.py"

Add-TestResult -Id "P7-F1" -Area "Phase7" -Description "fingerprint.py exists" `
    -Passed (Test-Path "F:\AION-ZERO\py\fingerprint.py") `
    -Details "Expected at F:\AION-ZERO\py\fingerprint.py"

# --- Test 2: Panic Lock currently NOT set ---

$panicLockPath = "F:\AION-ZERO\JARVIS.PANIC.LOCK"
$panicLockExists = Test-Path $panicLockPath

Add-TestResult -Id "P1-K1" -Area "Phase1" -Description "Panic Lock not active" `
    -Passed (-not $panicLockExists) `
    -Details ("File should NOT exist under normal operation: {0}" -f $panicLockPath)

# --- Test 3: CommandsApi Health (if reachable) ---

try {
    $health = Invoke-RestMethod -Method Get -Uri "http://127.0.0.1:5051/health" -TimeoutSec 3
    $ok = $health.status -eq "ok"
    Add-TestResult -Id "P1-A1" -Area "Phase1" -Description "CommandsApi healthcheck" `
        -Passed $ok `
        -Details ("Response: " + ($health | ConvertTo-Json -Compress))
}
catch {
    Add-TestResult -Id "P1-A1" -Area "Phase1" -Description "CommandsApi healthcheck" `
        -Passed $false `
        -Details ("Error calling /health: " + $_.Exception.Message)
}

# --- Test 4: Budget Cap EnvVar ---
# Checking .env or process env. Assuming .env load or set in session.
# We'll check process env primarily.
$budget = $env:AZ_BUDGET_CAP_USD
if (-not $budget) {
    # Try loading .env if not set
    if (Test-Path "F:\AION-ZERO\.env") {
        Get-Content "F:\AION-ZERO\.env" | ForEach-Object {
            if ($_ -match "^AZ_BUDGET_CAP_USD=(.*)") { $budget = $Matches[1] }
        }
    }
}
$hasBudget = -not [string]::IsNullOrWhiteSpace($budget)

Add-TestResult -Id "P3-B1" -Area "Phase3" -Description "Budget cap environment variable set" `
    -Passed $hasBudget `
    -Details ("AZ_BUDGET_CAP_USD=" + ($budget | Out-String))

# --- Test 5: Scheduled Tasks for core agents ---

$expectedTasks = @(
    "Jarvis-CommandsApi",
    "Jarvis-HealthWatchdog",
    "Jarvis-GraphBuilderWorker",
    "Jarvis-Reflex",
    "Jarvis-RevenueGen",
    "Jarvis-DocGen"
)

foreach ($taskName in $expectedTasks) {
    try {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
        $runningOrReady = $task.State -in @("Ready", "Running")
        Add-TestResult -Id ("SCH-" + $taskName) -Area "ScheduledTasks" `
            -Description ("Task '" + $taskName + "' exists and is Ready/Running") `
            -Passed $runningOrReady `
            -Details ("State=" + $task.State)
    }
    catch {
        Add-TestResult -Id ("SCH-" + $taskName) -Area "ScheduledTasks" `
            -Description ("Task '" + $taskName + "' exists and is Ready/Running") `
            -Passed $false `
            -Details ("Task not found or error: " + $_.Exception.Message)
    }
}

# --- Test 6: Citadel reachable (optional) ---

try {
    $citadelResponse = Invoke-WebRequest -Uri "http://localhost:9000" -TimeoutSec 3 -UseBasicParsing
    $citadelUp = $citadelResponse.StatusCode -eq 200
    Add-TestResult -Id "P6-C1" -Area "Phase6" -Description "Citadel HTTP reachable" `
        -Passed $citadelUp `
        -Details ("StatusCode=" + $citadelResponse.StatusCode)
}
catch {
    Add-TestResult -Id "P6-C1" -Area "Phase6" -Description "Citadel HTTP reachable" `
        -Passed $false `
        -Details ("Error calling Citadel: " + $_.Exception.Message)
}

# --- Save report ---

try {
    $resultsJson = $results | ConvertTo-Json -Depth 5
    $dir = Split-Path $ReportPath
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
    $resultsJson | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host ""
    Write-Host "=== Hardening Self-Test Completed ==="
    Write-Host ("Report saved to: {0}" -f $ReportPath)
}
catch {
    Write-Host "WARNING: Failed to write JSON report: $($_.Exception.Message)"
}
