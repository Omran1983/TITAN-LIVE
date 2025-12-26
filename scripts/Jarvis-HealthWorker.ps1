param(
    [string]$Project = "AION-ZERO",

    [string]$SupabaseUrl        = $env:SUPABASE_URL,
    [string]$SupabaseServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY,

    [string]$HealthTable   = "az_health_snapshots",
    [string]$CommandsTable = "az_commands"
)

$ErrorActionPreference = "Stop"

# --- Setup paths + logging ---------------------------------------------------

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile   = Join-Path $ScriptDir "Jarvis-HealthWorker.log"

if (-not (Test-Path $LogFile)) {
    try { New-Item -Path $LogFile -ItemType File -Force | Out-Null } catch {}
}

function Write-HealthLog {
    param([string]$Message)
    $ts  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $msg = "HealthWorker [$ts] $Message"
    Write-Host $msg
    if ($LogFile -and $LogFile.Trim() -ne "") {
        try { Add-Content -LiteralPath $LogFile -Value $msg } catch {}
    }
}

# --- Load env ---------------------------------------------------------------

$loadEnvPath = Join-Path $ScriptDir "Jarvis-LoadEnv.ps1"
if (Test-Path $loadEnvPath) {
    try {
        & $loadEnvPath | Out-Null
        Write-HealthLog "Loaded environment from Jarvis-LoadEnv.ps1."
    } catch {
        Write-HealthLog "WARNING: Failed to load env from Jarvis-LoadEnv.ps1: $($_.Exception.Message)"
    }
}

if (-not $SupabaseUrl)        { $SupabaseUrl        = $env:SUPABASE_URL }
if (-not $SupabaseServiceKey) { $SupabaseServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY }

if (-not $SupabaseUrl -or -not $SupabaseServiceKey) {
    Write-HealthLog "ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set. Aborting."
    Write-HealthLog "=== Jarvis-HealthWorker end (missing env) ==="
    return
}

$HealthEndpoint   = "$SupabaseUrl/rest/v1/$HealthTable"
$CommandsEndpoint = "$SupabaseUrl/rest/v1/$CommandsTable"

$CommonHeaders = @{
    "apikey"        = $SupabaseServiceKey
    "Authorization" = "Bearer $SupabaseServiceKey"
    "Content-Type"  = "application/json"
    "Prefer"        = "return=representation"
}

Write-HealthLog "=== Jarvis-HealthWorker start ==="
Write-HealthLog "HealthEndpoint   = $HealthEndpoint"
Write-HealthLog "CommandsEndpoint = $CommandsEndpoint"

# --- Compute metrics ---------------------------------------------------------

# 1) Queue depth: all queued commands for this project
try {
    $queueUrl  = "$CommandsEndpoint?project=eq.$Project&status=eq.queued&select=id"
    $queued    = Invoke-RestMethod -Method Get -Uri $queueUrl -Headers $CommonHeaders
    if ($null -eq $queued) {
        $queueDepth = 0
    } elseif ($queued -is [System.Array]) {
        $queueDepth = $queued.Count
    } else {
        $queueDepth = 1
    }
}
catch {
    Write-HealthLog "ERROR fetching queue depth: $($_.Exception.Message)"
    $queueDepth = $null
}

# 2) Errors last 10 minutes (approx): status=error & created_at >= now-10m
$errorsLast10 = 0
try {
    $tenMinutesAgoUtc = (Get-Date).ToUniversalTime().AddMinutes(-10).ToString("o")
    $errorsUrl = "$CommandsEndpoint?project=eq.$Project&status=eq.error&created_at=gte.$tenMinutesAgoUtc&select=id"
    $errors    = Invoke-RestMethod -Method Get -Uri $errorsUrl -Headers $CommonHeaders
    if ($null -eq $errors) {
        $errorsLast10 = 0
    } elseif ($errors -is [System.Array]) {
        $errorsLast10 = $errors.Count
    } else {
        $errorsLast10 = 1
    }
}
catch {
    Write-HealthLog "ERROR fetching errors_last_10m: $($_.Exception.Message)"
    $errorsLast10 = $null
}

# 3) Latency metric placeholder (0 for now, can be wired to real timing metric later)
$avgLatencyMs = 0

# 4) Derive overall_status from metrics
$overallStatus = "ok"

if ($queueDepth -eq $null -or $errorsLast10 -eq $null) {
    $overallStatus = "degraded"
}
else {
    if ($queueDepth -le 10 -and $errorsLast10 -le 0) {
        $overallStatus = "ok"
    }
    elseif ($queueDepth -le 50 -and $errorsLast10 -le 5) {
        $overallStatus = "warning"
    }
    else {
        $overallStatus = "critical"
    }
}

Write-HealthLog "Metrics: queue_depth=$queueDepth errors_last_10m=$errorsLast10 avg_latency_ms=$avgLatencyMs overall_status=$overallStatus"

# --- Insert snapshot ---------------------------------------------------------

$meta = @{
    source = "Jarvis-HealthWorker"
    host   = $env:COMPUTERNAME
}

$body = @{
    project          = $Project
    overall_status   = $overallStatus
    queue_depth      = $queueDepth
    errors_last_10m  = $errorsLast10
    avg_latency_ms   = $avgLatencyMs
    meta             = $meta
}

$json = $body | ConvertTo-Json -Depth 10

Write-HealthLog "POST $HealthEndpoint"
Write-HealthLog "Body: $json"

try {
    $resp = Invoke-RestMethod -Method Post -Uri $HealthEndpoint -Headers $CommonHeaders -Body $json
    if ($resp -is [System.Array]) { $resp = $resp[0] }
    Write-HealthLog "Inserted health snapshot id=$($resp.id) status=$($resp.overall_status) queue=$($resp.queue_depth) errors=$($resp.errors_last_10m)"
}
catch {
    Write-HealthLog "ERROR inserting health snapshot: $($_.Exception.Message)"
    Write-HealthLog "=== Jarvis-HealthWorker end (insert error) ==="
    return
}

Write-HealthLog "=== Jarvis-HealthWorker end (ok) ==="
