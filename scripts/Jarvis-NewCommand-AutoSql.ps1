param(
    [Parameter(Mandatory = $true)]
    [string] $CommandText
)

Write-Host "=== Jarvis-NewCommand-AutoSql ===" -ForegroundColor Cyan
Write-Host "CommandText: $CommandText" -ForegroundColor DarkCyan

# 1) Load .env via existing loader
$loadEnv = "F:\AION-ZERO\scripts\Jarvis-LoadEnv.ps1"
if (Test-Path $loadEnv) {
    & $loadEnv
} else {
    Write-Host "WARNING: Jarvis-LoadEnv.ps1 not found at $loadEnv" -ForegroundColor Yellow
}

# 2) Resolve Supabase URL + service key from env
$sbUrl = $env:JARVIS_SUPABASE_URL
if (-not $sbUrl) { $sbUrl = $env:SUPABASE_URL }

$sbKey = $env:JARVIS_SUPABASE_SERVICE_ROLE
if (-not $sbKey) { $sbKey = $env:SUPABASE_SERVICE_KEY }

if (-not $sbUrl -or -not $sbKey) {
    Write-Host "ERROR: SUPABASE_URL or SUPABASE_SERVICE_KEY not set in environment." -ForegroundColor Red
    Write-Host "Check F:\AION-ZERO\.env for SUPABASE_URL and SUPABASE_SERVICE_KEY entries." -ForegroundColor Yellow
    exit 1
}

Write-Host "Using Supabase URL: $sbUrl" -ForegroundColor DarkGray

# 3) Prepare headers
$headers = @{
    apikey         = $sbKey
    Authorization  = "Bearer $sbKey"
    Accept         = "application/json"
    "Content-Type" = "application/json"
    Prefer         = "return=representation"
}

# 4) Build body for az_commands
$bodyObj = @{
    project       = "AION-ZERO"
    target_agent  = "jarvis_auto_sql"
    command       = $CommandText
    command_type  = "auto_sql"
    action        = "auto_sql"
    status        = "queued"
    priority      = 5
    created_at    = (Get-Date).ToUniversalTime().ToString("o")
}

$bodyJson = $bodyObj | ConvertTo-Json -Depth 5

Write-Host "POSTing new az_commands row to $sbUrl/rest/v1/az_commands" -ForegroundColor DarkGray

try {
    $resp = Invoke-RestMethod `
        -Method Post `
        -Uri "$sbUrl/rest/v1/az_commands" `
        -Headers $headers `
        -Body $bodyJson

    if (-not $resp) {
        Write-Host "No response body returned. Check Supabase 'Prefer' header or logs." -ForegroundColor Yellow
        exit 1
    }

    # Supabase returns an array when Prefer=return=representation
    if ($resp -is [System.Array]) {
        $row = $resp[0]
    } else {
        $row = $resp
    }

    Write-Host ""
    Write-Host "Created command row:" -ForegroundColor Green
    $row | Format-List

    $cmdId = $row.id
    Write-Host ""
    Write-Host "Created command id = $cmdId" -ForegroundColor Green
}
catch {
    Write-Host "ERROR posting az_commands row:" -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
    exit 1
}
