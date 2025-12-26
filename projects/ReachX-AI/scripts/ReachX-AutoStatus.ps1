Param(
    [string]$EnvMainPath = "F:\secrets\.env-main"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $EnvMainPath)) {
    Write-Host "Missing env file: $EnvMainPath" -ForegroundColor Red
    exit 1
}

$lines     = Get-Content $EnvMainPath
$supLine   = $lines | Where-Object { $_ -match "^\s*SUPABASE_URL=" }         | Select-Object -Last 1
$keyLine   = $lines | Where-Object { $_ -match "^\s*SUPABASE_SERVICE_KEY=" } | Select-Object -Last 1

$SupabaseUrl = ($supLine -replace "^\s*SUPABASE_URL=", "").Trim()
$ServiceKey  = ($keyLine -replace "^\s*SUPABASE_SERVICE_KEY=", "").Trim()

if (-not $SupabaseUrl -or -not $ServiceKey) {
    Write-Host "SUPABASE_URL or SUPABASE_SERVICE_KEY missing in $EnvMainPath" -ForegroundColor Red
    exit 1
}

$Headers = @{
    apikey        = $ServiceKey
    Authorization = "Bearer $ServiceKey"
}

Write-Host "=== ReachX Automation Status ===" -ForegroundColor Cyan

# 1) Queued / error / done commands for ReachX
$commandsUrl = "$SupabaseUrl/rest/v1/az_commands?select=id,command,status,created_at&project=eq.ReachX&order=id.desc&limit=20"
try {
    $cmds = Invoke-RestMethod -Uri $commandsUrl -Headers $Headers -Method Get
    Write-Host "`n[Recent ReachX commands]" -ForegroundColor Yellow
    $cmds | Select-Object id,command,status,created_at | Format-Table
} catch {
    Write-Host "Failed to query az_commands: $($_.Exception.Message)" -ForegroundColor Red
}

# 2) Check if Jarvis-CommandWorker.ps1 is running
Write-Host "`n[Jarvis-CommandWorker process]" -ForegroundColor Yellow
Get-Process | Where-Object { $_.Path -like "*Jarvis-CommandWorker.ps1*" } | Select-Object Id,ProcessName,Path

# 3) Check for scheduled ReachX-Autopilot task
Write-Host "`n[Scheduled Task: ReachX-Autopilot]" -ForegroundColor Yellow
try {
    schtasks /Query /TN "ReachX-Autopilot" /V /FO LIST 2>$null
} catch {
    Write-Host "ReachX-Autopilot task not found." -ForegroundColor DarkYellow
}

Write-Host "`nDone." -ForegroundColor Green
