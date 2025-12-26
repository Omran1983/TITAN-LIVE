<#
    Jarvis-HealthMarkOk.ps1
    Writes a "healthy" snapshot into az_health_snapshots.

    Usage:
        cd F:\AION-ZERO\scripts
        powershell -NoProfile -ExecutionPolicy Bypass -File .\Jarvis-HealthMarkOk.ps1

    Optional params (if you want to override defaults later):
        -QueueDepth 5 -ErrorsLast10m 0 -AvgLatencyMs 150
#>

param(
    [int]$QueueDepth      = 3,
    [int]$ErrorsLast10m   = 0,
    [int]$AvgLatencyMs    = 150
)

Write-Host "=== Jarvis-HealthMarkOk ==="

# Resolve script directory and load environment
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

$loadEnvPath = Join-Path $scriptDir "Jarvis-LoadEnv.ps1"
if (Test-Path $loadEnvPath) {
    Write-Host "Loading environment from .env via Jarvis-LoadEnv.ps1 ..."
    & $loadEnvPath
} else {
    Write-Host "WARNING: Jarvis-LoadEnv.ps1 not found. Assuming env vars already set."
}

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is not set in the environment."
    exit 1
}

$healthEndpoint = "$($env:SUPABASE_URL)/rest/v1/az_health_snapshots"
Write-Host "HealthEndpoint = $healthEndpoint"

$nowUtc = (Get-Date).ToUniversalTime().ToString("o")

$bodyObject = @{
    overall_status   = "ok"
    queue_depth      = $QueueDepth
    errors_last_10m  = $ErrorsLast10m
    avg_latency_ms   = $AvgLatencyMs
    meta             = @{
        source   = "Jarvis-HealthMarkOk"
        message  = "Manual OK snapshot after incident/test."
        created  = $nowUtc
        test     = $false
    }
}

$bodyJson = $bodyObject | ConvertTo-Json -Depth 5

Write-Host "Inserting OK health snapshot at $nowUtc ..."
Write-Host $bodyJson

$headers = @{
    apikey         = $env:SUPABASE_SERVICE_ROLE_KEY
    Authorization  = "Bearer $($env:SUPABASE_SERVICE_ROLE_KEY)"
    Accept         = "application/json"
    "Content-Type" = "application/json"
    Prefer         = "return=representation"
}

try {
    $response = Invoke-RestMethod -Method Post -Uri $healthEndpoint -Headers $headers -Body $bodyJson
    Write-Host "Insert response:"
    $response | ConvertTo-Json -Depth 5
    Write-Host "=== Jarvis-HealthMarkOk: DONE ==="
} catch {
    Write-Host "ERROR: Failed to insert OK health snapshot."
    Write-Host $_.Exception.Message
    if ($_.ErrorDetails) {
        Write-Host $_.ErrorDetails
    }
    exit 1
}
