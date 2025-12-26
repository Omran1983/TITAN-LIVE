param(
    [Parameter(Mandatory = $true)][string]$Project,
    [Parameter(Mandatory = $true)][string]$Title,
    [Parameter(Mandatory = $true)][string]$Goal,
    [ValidateSet("low","medium","high","critical")]
    [string]$RiskLevel = "medium",
    [ValidateSet("autopilot","approval_required")]
    [string]$AutopilotMode = "approval_required",
    [string]$CreatedBy = "omran"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load env (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
. "$scriptDir\Jarvis-LoadEnv.ps1"

$supabaseUrl = $env:SUPABASE_URL
$serviceKey  = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $supabaseUrl -or -not $serviceKey) {
    throw "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set in environment."
}

$headers = @{
    apikey        = $serviceKey
    Authorization = "Bearer $serviceKey"
    Prefer        = "return=representation"
}

Write-Host "=== Jarvis-NewMission ==="
Write-Host "Project: $Project"
Write-Host "Title  : $Title"
Write-Host "Risk   : $RiskLevel"
Write-Host "Mode   : $AutopilotMode"

$body = @(
    @{

        project        = $Project
        title          = $Title
        goal           = $Goal
        risk_level     = $RiskLevel
        status         = "queued"
        created_by     = $CreatedBy
        autopilot_mode = $AutopilotMode
    }
) | ConvertTo-Json

# ?select=* makes sure Supabase returns the row we just inserted
$resp = Invoke-RestMethod -Method Post `
    -Uri "$supabaseUrl/rest/v1/az_missions?select=*" `
    -Headers $headers -ContentType "application/json" -Body $body

if ($resp -and $resp[0].id) {
    $id = $resp[0].id

    # ✅ keep emoji *inside* a string so it never becomes a command
    $check = [char]0x2705

    Write-Host ""
    Write-Host ("{0} Mission created with id = {1}" -f $check, $id) -ForegroundColor Green
}
else {
    Write-Warning "Mission created but no id returned:"
    $resp | ConvertTo-Json -Depth 10
}
