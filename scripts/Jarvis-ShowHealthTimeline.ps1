param(
    # How many snapshots to show
    [int]$Limit = 50
)

$ErrorActionPreference = "Stop"

Write-Host "=== Jarvis-ShowHealthTimeline ==="
Write-Host ("Limit = {0}" -f $Limit)

# --- Load env so SUPABASE_URL / SERVICE_ROLE are available ---

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$loadEnv   = Join-Path $scriptDir "Jarvis-LoadEnv.ps1"

if (Test-Path $loadEnv) {
    Write-Host "Loading environment from .env via Jarvis-LoadEnv.ps1 ..."
    & $loadEnv
} else {
    Write-Host "WARNING: Jarvis-LoadEnv.ps1 not found. Assuming env vars are already set."
}

$SupabaseUrl        = $env:SUPABASE_URL
$SupabaseServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $SupabaseUrl -or -not $SupabaseServiceKey) {
    Write-Host "ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is not set. Aborting."
    exit 1
}

$HealthEndpoint = "$SupabaseUrl/rest/v1/az_health_snapshots"

$headers = @{
    apikey        = $SupabaseServiceKey
    Authorization = "Bearer $SupabaseServiceKey"
    Accept        = "application/json"
}

# --- Fetch latest snapshots ---

$query =
    "?select=id,created_at,overall_status,queue_depth,errors_last_10m,avg_latency_ms,meta" +
    "&order=created_at.desc" +
    "&limit=$Limit"

$url = "$HealthEndpoint$query"

Write-Host ("Fetching health snapshots from: {0}" -f $url)

try {
    $resp = Invoke-RestMethod -Method Get -Uri $url -Headers $headers
} catch {
    Write-Host ("ERROR: Failed to fetch health snapshots: {0}" -f $_.Exception.Message)
    exit 1
}

if ($null -eq $resp) {
    Write-Host "No health snapshots found."
    exit 0
}

if ($resp -isnot [System.Array]) {
    $resp = @($resp)
}

if ($resp.Count -eq 0) {
    Write-Host "No health snapshots found."
    exit 0
}

# --- Build timeline with age in minutes ---

$nowUtc = (Get-Date).ToUniversalTime()

$timeline = foreach ($row in $resp) {
    $createdUtc = [datetime]$row.created_at
    $ageMinutes = [math]::Round( ($nowUtc - $createdUtc).TotalMinutes, 1 )

    # Optional meta.message if present
    $msg = $null
    if ($row.meta -and $row.meta.message) {
        $msg = $row.meta.message
    }

    [pscustomobject]@{
        id              = $row.id
        created_at      = $row.created_at
        age_min         = $ageMinutes
        status          = $row.overall_status
        queue_depth     = $row.queue_depth
        errors_last_10m = $row.errors_last_10m
        avg_latency_ms  = $row.avg_latency_ms
        message         = $msg
    }
}

Write-Host ""
Write-Host "Recent health timeline (most recent first):"
Write-Host ""

$timeline |
    Sort-Object created_at -Descending |
    Format-Table -AutoSize

Write-Host ""
Write-Host "=== Jarvis-ShowHealthTimeline complete ==="
