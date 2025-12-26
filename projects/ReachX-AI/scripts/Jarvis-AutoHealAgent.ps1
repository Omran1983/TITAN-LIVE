<# 
    F:\AION-ZERO\scripts\Jarvis-AutoHealAgent.ps1

    One-shot AutoHeal Agent:
    - Loads env from .env-main (via Use-ProjectEnv.ps1) if present
    - Resolves SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY
    - Writes a heartbeat into logs\autoheal.log
    - (Optional) Posts a heartbeat row into jarvis_healthchecks table
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

# --- Paths -------------------------------------------------------------
$projectRoot = "F:\AION-ZERO"
$logDir     = Join-Path $projectRoot "logs"
$logFile    = Join-Path $logDir "autoheal.log"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts`t$Message" | Tee-Object -FilePath $logFile -Append
}

Write-Log "=== Jarvis-AutoHealAgent starting ==="

# --- Load env (.env-main -> Use-ProjectEnv.ps1) ------------------------
$envFile   = Join-Path $projectRoot ".env-main"
$envLoader = Join-Path $projectRoot "scripts\Use-ProjectEnv.ps1"

if (Test-Path $envFile -and Test-Path $envLoader) {
    Write-Log "Loading environment from $envFile"
    . $envLoader -EnvFilePath $envFile
} else {
    Write-Log "WARNING: .env-main and/or Use-ProjectEnv.ps1 not found, using current process env only."
}

# --- Resolve Supabase config ------------------------------------------
if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Log "ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set in environment."
    Write-Log "       Set them in .env-main or system env and re-run."
    exit 1
}

$supabaseUrl        = $env:SUPABASE_URL.TrimEnd("/")
$supabaseServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY

Write-Log "Supabase URL resolved to: $supabaseUrl"

# --- Optional: Post a heartbeat row to Supabase -----------------------
# Requires table: jarvis_healthchecks (id, source, status, details, created_at ...)
$healthUrl = "$supabaseUrl/rest/v1/jarvis_healthchecks"

$headers = @{
    "apikey"        = $supabaseServiceKey
    "Authorization" = "Bearer $supabaseServiceKey"
    "Content-Type"  = "application/json"
    "Prefer"        = "return=minimal"
}

$bodyObj = @{
    source     = "autoheal_agent"
    status     = "ok"
    details    = "AutoHealAgent heartbeat"
    created_at = (Get-Date).ToString("o")
}
$bodyJson = $bodyObj | ConvertTo-Json

try {
    Write-Log "Posting heartbeat to Supabase jarvis_healthchecks..."
    $null = Invoke-RestMethod -Method Post -Uri $healthUrl -Headers $headers -Body $bodyJson
    Write-Log "Heartbeat posted successfully."
} catch {
    Write-Log "ERROR posting heartbeat: $($_.Exception.Message)"
    # log error but don't hard crash
}

Write-Log "=== Jarvis-AutoHealAgent finished ==="
exit 0
