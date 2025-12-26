# F:\AION-ZERO\scripts\Show-AgentSummary.ps1

$ErrorActionPreference = 'Stop'

Write-Host "=== Jarvis - Agent Summary ===" -ForegroundColor Cyan

# 1) Load .env via Jarvis-LoadEnv.ps1 so SUPABASE_* are available
$loadEnv = "F:\AION-ZERO\scripts\Jarvis-LoadEnv.ps1"
if (Test-Path $loadEnv) {
    & $loadEnv
} else {
    Write-Host "WARNING: Jarvis-LoadEnv.ps1 not found at $loadEnv" -ForegroundColor Yellow
}

# 2) Resolve Supabase URL + service key from environment
$sbUrl = $env:JARVIS_SUPABASE_URL
if (-not $sbUrl) { $sbUrl = $env:SUPABASE_URL }

$sbKey = $env:JARVIS_SUPABASE_SERVICE_ROLE
if (-not $sbKey) { $sbKey = $env:SUPABASE_SERVICE_KEY }

if (-not $sbUrl -or -not $sbKey) {
    Write-Host "ERROR: SUPABASE_URL / SERVICE_KEY env vars are missing." -ForegroundColor Red
    Write-Host "Check your .env and Jarvis-LoadEnv.ps1." -ForegroundColor Red
    exit 1
}

# 3) Build headers for Supabase REST
$SBHeaders = @{
    apikey         = $sbKey
    Authorization  = "Bearer $sbKey"
    Accept         = "application/json"
    "Content-Type" = "application/json"
}

# 4) Fetch recent health snapshots (if table exists)
Write-Host ""
Write-Host "-> Fetching latest az_health_snapshots (if available) ..." -ForegroundColor DarkGray

$healthUri = "$sbUrl/rest/v1/az_health_snapshots?select=created_at,overall_status,queue_depth,errors_last_10m,avg_latency_ms&order=created_at.desc&limit=10"

try {
    $health = Invoke-RestMethod -Uri $healthUri -Headers $SBHeaders -Method Get

    if (-not $health) {
        Write-Host "No rows in az_health_snapshots yet." -ForegroundColor Yellow
    } else {
        if ($health -isnot [System.Array]) { $health = @($health) }

        Write-Host ""
        Write-Host "Recent health snapshots:" -ForegroundColor Green
        $health |
            Select-Object created_at, overall_status, queue_depth, errors_last_10m, avg_latency_ms |
            Format-Table -AutoSize
    }
}
catch {
    Write-Host "Note: Could not read az_health_snapshots (table missing or not yet wired)." -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
}

# 5) Fetch last 10 az_commands for quick view
Write-Host ""
Write-Host "-> Fetching last 10 az_commands ..." -ForegroundColor DarkGray

$cmdUri = "$sbUrl/rest/v1/az_commands?select=id,project,agent,action,status,created_at&order=created_at.desc&limit=10"

try {
    $cmds = Invoke-RestMethod -Uri $cmdUri -Headers $SBHeaders -Method Get

    if (-not $cmds) {
        Write-Host "No az_commands rows found." -ForegroundColor Yellow
    } else {
        if ($cmds -isnot [System.Array]) { $cmds = @($cmds) }

        Write-Host ""
        Write-Host "Last 10 commands:" -ForegroundColor Green
        $cmds |
            Select-Object id, project, agent, action, status, created_at |
            Format-Table -AutoSize
    }
}
catch {
    Write-Host "ERROR: Failed to fetch az_commands." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "=== Agent summary complete ===" -ForegroundColor Cyan
