param(
    [string]$Project = "AION-ZERO",
    [int]$Limit = 20
)

$ErrorActionPreference = "Stop"

Write-Host "=== Jarvis-ShowReflexSummary ==="
Write-Host ("Project = {0}, Limit = {1}" -f $Project, $Limit)

# Load env (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$loadEnv   = Join-Path $scriptDir "Jarvis-LoadEnv.ps1"

if (Test-Path $loadEnv) {
    Write-Host "Loading environment from .env via Jarvis-LoadEnv.ps1 ..."
    & $loadEnv
} else {
    Write-Host "WARNING: Jarvis-LoadEnv.ps1 not found. Assuming env vars are already set."
}

$SupabaseUrl       = $env:SUPABASE_URL
$SupabaseServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $SupabaseUrl -or -not $SupabaseServiceKey) {
    Write-Host "ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is not set. Aborting."
    exit 1
}

$CommandsEndpoint = "$SupabaseUrl/rest/v1/az_commands"

$headers = @{
    apikey        = $SupabaseServiceKey
    Authorization = "Bearer $SupabaseServiceKey"
    Accept        = "application/json"
}

# Build query: latest reflex commands for this project
$projectEsc = [Uri]::EscapeDataString($Project)
$limitEsc   = $Limit

$query =
    "?select=id,project,action,status,created_at,updated_at,args,result_json,logs" +
    "&project=eq.$projectEsc" +
    "&action=eq.reflex" +
    "&order=created_at.desc" +
    "&limit=$limitEsc"

$url = "$CommandsEndpoint$query"

Write-Host ("Fetching reflex commands from: {0}" -f $url)

try {
    $resp = Invoke-RestMethod -Method Get -Uri $url -Headers $headers
} catch {
    Write-Host ("ERROR: Failed to fetch reflex commands: {0}" -f $_.Exception.Message)
    exit 1
}

if ($null -eq $resp) {
    Write-Host "No reflex commands found."
    exit 0
}

# Normalize to array
if ($resp -isnot [System.Array]) {
    $resp = @($resp)
}

if ($resp.Count -eq 0) {
    Write-Host "No reflex commands found."
    exit 0
}

# Project into a friendly summary
$summary = foreach ($cmd in $resp) {
    $ruleName   = $null
    $trigger    = $null
    $reason     = $null
    $handledAt  = $null

    # Prefer args fields if present
    if ($cmd.args) {
        $ruleName = $cmd.args.rule_name
        $trigger  = $cmd.args.trigger
        $reason   = $cmd.args.reason
    }

    # Try to parse result_json if present (it is stored as a JSON string)
    if ($cmd.result_json) {
        try {
            $rj = $cmd.result_json | ConvertFrom-Json -ErrorAction Stop
            if (-not $ruleName -and $rj.rule_name)   { $ruleName = $rj.rule_name }
            if (-not $trigger  -and $rj.trigger)     { $trigger  = $rj.trigger }
            if (-not $reason   -and $rj.reason)      { $reason   = $rj.reason }
            if ($rj.handled_at_utc)                  { $handledAt = $rj.handled_at_utc }
        } catch {
            # ignore JSON parse errors for result_json
        }
    }

    [pscustomobject]@{
        id          = $cmd.id
        status      = $cmd.status
        rule        = $ruleName
        trigger     = $trigger
        created_at  = $cmd.created_at
        handled_at  = $handledAt
        reason      = $reason
        logs        = $cmd.logs
    }
}

Write-Host ""
Write-Host "Recent reflex incidents:"
Write-Host ""

$summary |
    Sort-Object created_at -Descending |
    Format-Table -AutoSize

Write-Host ""
Write-Host "=== Jarvis-ShowReflexSummary complete ==="
