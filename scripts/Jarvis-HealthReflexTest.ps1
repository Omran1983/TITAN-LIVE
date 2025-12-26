<#
    Jarvis-HealthReflexTest.ps1
    Injects a synthetic "bad" health snapshot into az_health_snapshots
    so that Jarvis-HealthReflexRules can trigger reflex actions.

    Usage:
        cd F:\AION-ZERO\scripts
        powershell -NoProfile -ExecutionPolicy Bypass -File .\Jarvis-HealthReflexTest.ps1
#>

Write-Host "=== Jarvis-HealthReflexTest ==="

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

# Build a synthetic "bad" snapshot
# You can tweak these values if you want to simulate other failure modes.
$nowUtc = (Get-Date).ToUniversalTime().ToString("o")

$bodyObject = @{
    overall_status   = "error"
    queue_depth      = 999
    errors_last_10m  = 25
    avg_latency_ms   = 5000
    meta             = @{
        source   = "Jarvis-HealthReflexTest"
        message  = "Synthetic test snapshot to trigger reflex rules."
        created  = $nowUtc
        test     = $true
    }
}

$bodyJson = $bodyObject | ConvertTo-Json -Depth 5

Write-Host "Inserting synthetic health snapshot at $nowUtc ..."
Write-Host $bodyJson

$headers = @{
    apikey        = $env:SUPABASE_SERVICE_ROLE_KEY
    Authorization = "Bearer $($env:SUPABASE_SERVICE_ROLE_KEY)"
    Accept        = "application/json"
    "Content-Type" = "application/json"
    Prefer        = "return=representation"
}

try {
    $response = Invoke-RestMethod -Method Post -Uri $healthEndpoint -Headers $headers -Body $bodyJson
    Write-Host "Insert response:"
    $response | ConvertTo-Json -Depth 5
    Write-Host "=== Jarvis-HealthReflexTest: DONE ==="
} catch {
    Write-Host "ERROR: Failed to insert synthetic health snapshot."
    Write-Host $_.Exception.Message
    if ($_.ErrorDetails) {
        Write-Host $_.ErrorDetails
    }
    exit 1
}
