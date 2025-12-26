<#
    Jarvis-Watchdog.ps1
    --------------------
    Lightweight watchdog that:

    - Ensures a logs folder exists
    - Writes a structured log line for every run
    - Checks a few critical components:
        * Jarvis Commands API (HTTP 5051 /health)
        * Required Scheduled Tasks
    - Inserts a structured "agent run" record into az_agent_runs via Supabase REST

    Log file:
        F:\AION-ZERO\logs\Jarvis-Watchdog.log
#>

$ErrorActionPreference = "Stop"

# --------- Paths & Logging ---------

$rootDir = "F:\AION-ZERO"

# Ensure Environment Variables are loaded (Robustness Fix)
if (Test-Path "$rootDir\scripts\Load-DotEnv.ps1") {
    . "$rootDir\scripts\Load-DotEnv.ps1" -EnvFilePath "$rootDir\.env" | Out-Null
}

$logDir = Join-Path $rootDir "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$logPath = Join-Path $logDir "Jarvis-Watchdog.log"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[{0}] [{1}] {2}" -f $timestamp, $Level, $Message
    Add-Content -Path $logPath -Value $line
}

Write-Log "=== Jarvis-Watchdog run started ==="

# --------- Supabase Helper ---------

function Write-AgentRunToSupabase {
    param(
        [string]$AgentName,
        [string]$Status,
        [string]$Severity,
        [datetime]$StartedAt,
        [datetime]$FinishedAt,
        [string]$ErrorCode,
        [string]$ErrorMessage,
        [object]$Payload
    )

    # Allow falling back to alternate env var names if needed
    $supabaseUrl = $env:SUPABASE_URL
    $supabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY
    
    if (-not $supabaseKey) { $supabaseKey = $env:SUPABASE_SERVICE_KEY }

    if (-not $supabaseUrl -or -not $supabaseKey) {
        Write-Log "Supabase env vars SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are missing." "ERROR"
        return
    }

    $runId = [guid]::NewGuid()

    $bodyObj = @{
        run_id        = $runId
        agent_name    = $AgentName
        mission_id    = $null
        status        = $Status
        severity      = $Severity
        started_at    = $StartedAt.ToUniversalTime().ToString("o")
        finished_at   = $FinishedAt.ToUniversalTime().ToString("o")
        error_code    = $ErrorCode
        error_message = $ErrorMessage
        payload       = $Payload
    }

    $bodyJson = $bodyObj | ConvertTo-Json -Depth 6

    $headers = @{
        "apikey"        = $supabaseKey
        "Authorization" = "Bearer $supabaseKey"
        "Content-Type"  = "application/json"
        "Prefer"        = "return=representation" 
    }

    $endpoint = "$supabaseUrl/rest/v1/az_agent_runs"

    try {
        Invoke-RestMethod -Method Post -Uri $endpoint -Headers $headers -Body $bodyJson | Out-Null
        Write-Log "Recorded agent run in az_agent_runs (run_id=$runId)." "INFO"
    }
    catch {
        Write-Log "Failed to record agent run in az_agent_runs: $($_.Exception.Message)" "ERROR"
        if ($_.Exception.Response) {
            # Basic debug of response body if available
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $respBody = $reader.ReadToEnd()
            Write-Log "Supabase Response: $respBody" "DEBUG"
        }
    }
}

# --------- Health Checks ---------

$hasError = $false
$checks = @()

$startTime = Get-Date

# Helper to record check results
function Add-CheckResult {
    param(
        [string]$Name,
        [string]$Status,   # 'ok' or 'fail'
        [string]$Message
    )
    $script:checks += [pscustomobject]@{
        name    = $Name
        status  = $Status
        message = $Message
    }
}

# 1) Commands API health check
$commandsApiUrl = "http://localhost:5051/health"

try {
    $resp = Invoke-WebRequest -Uri $commandsApiUrl -UseBasicParsing -TimeoutSec 5
    if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 300) {
        Add-CheckResult -Name "CommandsAPI" -Status "ok" -Message "Status $($resp.StatusCode)"
        Write-Log "Commands API reachable at $commandsApiUrl (status $($resp.StatusCode))."
    }
    else {
        Add-CheckResult -Name "CommandsAPI" -Status "fail" -Message "Non-2xx status $($resp.StatusCode)"
        Write-Log "Commands API responded with non-2xx status $($resp.StatusCode)." "WARN"
        $hasError = $true
    }
}
catch {
    Add-CheckResult -Name "CommandsAPI" -Status "fail" -Message $_.Exception.Message
    Write-Log "Commands API health check failed: $($_.Exception.Message)" "ERROR"
    $hasError = $true
}

# 2) Check required Scheduled Tasks
$requiredTasks = @(
    "Jarvis-RunLoop-reachx",
    "Jarvis-HeartbeatBeacon"
)

foreach ($taskName in $requiredTasks) {
    # Check standard way
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($null -eq $task) {
        Add-CheckResult -Name "ScheduledTask:$taskName" -Status "fail" -Message "Task missing"
        Write-Log "Scheduled Task '$taskName' is MISSING." "WARN"
        $hasError = $true
    }
    else {
        Add-CheckResult -Name "ScheduledTask:$taskName" -Status "ok" -Message "Task present"
        Write-Log "Scheduled Task '$taskName' is present."
    }
}

# --------- Final Status & Supabase Write ---------

$endTime = Get-Date

$failedChecks = $checks | Where-Object { $_.status -eq "fail" }

if ($hasError) {
    $status = "soft_fail"
    $severity = "warning"
    $errorCode = "WATCHDOG_ISSUES"
    $errorMsg = if ($failedChecks.Count -gt 0) {
        "Failed checks: " + ($failedChecks.name -join ", ")
    }
    else {
        "One or more checks reported issues."
    }
    Write-Log "Jarvis-Watchdog completed with warnings/errors: $errorMsg" "WARN"
}
else {
    $status = "success"
    $severity = "info"
    $errorCode = $null
    $errorMsg = $null
    Write-Log "Jarvis-Watchdog run completed successfully."
}

# Build payload for az_agent_runs (jsonb)
$payload = @{
    checks  = $checks
    summary = @{
        total  = $checks.Count
        failed = $failedChecks.Count
    }
}

# Write to Supabase
Write-AgentRunToSupabase `
    -AgentName  "Jarvis-Watchdog" `
    -Status     $status `
    -Severity   $severity `
    -StartedAt  $startTime `
    -FinishedAt $endTime `
    -ErrorCode  $errorCode `
    -ErrorMessage $errorMsg `
    -Payload    $payload

# Exit code for OS / scheduler
if ($hasError) {
    exit 1
}
else {
    exit 0
}
