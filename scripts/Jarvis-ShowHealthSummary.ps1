Write-Host "=== Jarvis-ShowHealthSummary ===" -ForegroundColor Cyan

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir  = Split-Path -Parent $scriptPath

# Load env
$envLoader = Join-Path $scriptDir "Jarvis-LoadEnv.ps1"
if (-not (Test-Path $envLoader)) {
    Write-Host "ERROR: Jarvis-LoadEnv.ps1 not found at $envLoader" -ForegroundColor Red
    exit 1
}
. $envLoader
Write-Host "Loaded environment from Jarvis-LoadEnv.ps1." -ForegroundColor DarkGray

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY missing." -ForegroundColor Red
    exit 1
}

$baseUrl = $env:SUPABASE_URL.Trim().TrimEnd('/')
$healthEndpoint = "$baseUrl/rest/v1/az_health_snapshots?select=*&order=created_at.desc&limit=1"

$headers = @{
    apikey         = $env:SUPABASE_SERVICE_ROLE_KEY
    Authorization  = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    Accept         = "application/json"
}

Write-Host "Fetching latest health..." -ForegroundColor DarkGray

try {
    $resp = Invoke-RestMethod -Method Get -Uri $healthEndpoint -Headers $headers -ErrorAction Stop
}
catch {
    Write-Host "ERROR: Failed to fetch health: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
        Write-Host "DETAILS: $($_.ErrorDetails.Message)" -ForegroundColor DarkRed
    }
    exit 1
}

if (-not $resp) {
    Write-Host "No health snapshots found." -ForegroundColor Yellow
    exit 0
}

$h = $resp[0]

# Compute age in minutes
$createdAt = [datetime]$h.created_at
$ageMin = [math]::Round((New-TimeSpan -Start $createdAt -End (Get-Date)).TotalMinutes, 1)

Write-Host ""
Write-Host "=== Latest Health Snapshot ===" -ForegroundColor Cyan
Write-Host ("ID              : {0}" -f $h.id)
Write-Host ("Created at      : {0}" -f $createdAt.ToString("yyyy-MM-dd HH:mm:ss"))
Write-Host ("Age (minutes)   : {0}" -f $ageMin)
Write-Host ("Project         : {0}" -f $h.project)
Write-Host ("Status          : {0}" -f $h.status)
Write-Host ("Overall status  : {0}" -f $h.overall_status)
Write-Host ("Queue           : {0}" -f $h.queue)
Write-Host ("Errors          : {0}" -f $h.errors)
Write-Host ("Latency         : {0}" -f $h.latency)
Write-Host ("Logs            : {0}" -f $h.logs)
Write-Host "==============================" -ForegroundColor Cyan

# Simple human verdict
if ($h.overall_status -eq "ok" -and $ageMin -le 15) {
    Write-Host "Verdict: SYSTEM HEALTHY ✅" -ForegroundColor Green
}
elseif ($ageMin -gt 15) {
    Write-Host "Verdict: STALE HEALTH ❗ (snapshot older than 15 minutes)" -ForegroundColor Yellow
}
else {
    Write-Host ("Verdict: DEGRADED ({0}) ⚠" -f $h.overall_status) -ForegroundColor Yellow
}
