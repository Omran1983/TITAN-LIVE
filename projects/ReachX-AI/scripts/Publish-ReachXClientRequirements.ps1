[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "=== ReachX: Publish Client Requirements ===" -ForegroundColor Cyan

$root    = "F:\ReachX-AI"
$csvPath = Join-Path $root "data\normalised\client_requirements.csv"

if (-not (Test-Path $csvPath)) {
    throw "CSV not found at: $csvPath"
}

# Make sure ReachX Supabase env is loaded (same as other scripts)
$loadEnv = Join-Path $root "scripts\Load-ReachXSupabase.ps1"
if (Test-Path $loadEnv) {
    . $loadEnv
}

if (-not $env:REACHX_SUPABASE_URL -or -not $env:REACHX_SUPABASE_SERVICE_KEY) {
    throw "REACHX_SUPABASE_URL / REACHX_SUPABASE_SERVICE_KEY not set."
}

$rows = Import-Csv $csvPath
if (-not $rows -or $rows.Count -eq 0) {
    throw "No rows in $csvPath"
}

$apiUrl = "$($env:REACHX_SUPABASE_URL)/rest/v1/reachx_client_requirements"

$headers = @{
    apikey        = $env:REACHX_SUPABASE_SERVICE_KEY
    Authorization = "Bearer $($env:REACHX_SUPABASE_SERVICE_KEY)"
    "Content-Type" = "application/json"
    Prefer        = "resolution=merge-duplicates"
}

Write-Host ("Publishing {0} rows to reachx_client_requirements..." -f $rows.Count) -ForegroundColor Yellow

# Supabase likes JSON array payload
$body = $rows | ConvertTo-Json -Depth 5

try {
    $resp = Invoke-RestMethod -Method Post -Uri $apiUrl -Headers $headers -Body $body
    Write-Host "Publish DONE." -ForegroundColor Green
}
catch {
    Write-Error "Failed to publish: $($_.Exception.Message)"
    throw
}
