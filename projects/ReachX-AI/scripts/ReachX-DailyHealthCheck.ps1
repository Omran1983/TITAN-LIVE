# ReachX-DailyHealthCheck.ps1
# - Uses SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY from env
# - Counts reachx_dormitories and reachx_workers via Supabase REST
# - Appends a summary line to F:\ReachX-AI\logs\daily_health.log

$ErrorActionPreference = "Stop"

# --------- Config ---------
$logPath = "F:\ReachX-AI\logs\daily_health.log"

# Ensure log directory exists
$logDir = Split-Path $logPath -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-HealthLog {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp - $Message"
    $line | Out-File -FilePath $logPath -Append -Encoding UTF8
}

# --------- Supabase env + headers ---------
$supabaseUrl = $env:SUPABASE_URL
$serviceKey  = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $supabaseUrl -or -not $serviceKey) {
    Write-HealthLog "ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set in environment."
    exit 1
}

$supabaseUrl = $supabaseUrl.TrimEnd("/")

$headers = @{
    "apikey"        = $serviceKey
    "Authorization" = "Bearer $serviceKey"
}

# --------- Helpers ---------

function Test-SupabaseConnection {
    param(
        [string]$BaseUrl,
        [hashtable]$Headers
    )

    try {
        $uri = "$BaseUrl/rest/v1/reachx_dormitories?select=id&limit=1"
        Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers -ErrorAction Stop | Out-Null
        Write-HealthLog "Supabase connectivity: OK ($uri)"
        return $true
    } catch {
        Write-HealthLog "Supabase connectivity: FAILED - $($_.Exception.Message)"
        return $false
    }
}

function Get-TableCount {
    param(
        [string]$BaseUrl,
        [hashtable]$Headers,
        [string]$TableName
    )

    try {
        # Simple approach: fetch all ids and count them in PowerShell
        $uri = "$BaseUrl/rest/v1/$TableName?select=id"
        $result = Invoke-RestMethod -Method Get -Uri $uri -Headers $Headers -ErrorAction Stop

        if ($null -eq $result) {
            $count = 0
        } elseif ($result -is [System.Array]) {
            $count = $result.Count
        } else {
            # Single object
            $count = 1
        }

        Write-HealthLog "Table '$TableName' has $count rows."
        return $count
    } catch {
        Write-HealthLog "ERROR: Failed to query '$TableName' - $($_.Exception.Message)"
        return $null
    }
}

# --------- Main ---------

Write-HealthLog "===== ReachX Daily Health Check START ====="

$ok = Test-SupabaseConnection -BaseUrl $supabaseUrl -Headers $headers
if (-not $ok) {
    Write-HealthLog "Aborting health check due to Supabase connectivity failure."
    Write-HealthLog "===== ReachX Daily Health Check END (FAILED) ====="
    exit 1
}

$dormCount   = Get-TableCount -BaseUrl $supabaseUrl -Headers $headers -TableName "reachx_dormitories"
$workerCount = Get-TableCount -BaseUrl $supabaseUrl -Headers $headers -TableName "reachx_workers"

$summary = "SUMMARY: Dormitories=$dormCount | Workers=$workerCount"
Write-HealthLog $summary

Write-HealthLog "===== ReachX Daily Health Check END (OK) ====="
