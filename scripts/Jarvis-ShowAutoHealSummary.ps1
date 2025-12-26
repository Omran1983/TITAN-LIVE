param(
    [string]$Project = "AION-ZERO",
    [int]$Limit = 20
)

$ErrorActionPreference = "Stop"

Write-Host "=== Jarvis-ShowAutoHealSummary ==="
Write-Host "Project = $Project, Limit = $Limit"

# Load env
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$loadEnvPath = Join-Path $ScriptDir "Jarvis-LoadEnv.ps1"
if (Test-Path $loadEnvPath) {
    & $loadEnvPath | Out-Null
}

$SupabaseUrl        = $env:SUPABASE_URL
$SupabaseServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $SupabaseUrl -or -not $SupabaseServiceKey) {
    Write-Error "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set."
    exit 1
}

$CommandsEndpoint = "$SupabaseUrl/rest/v1/az_commands"

$headers = @{
    apikey        = $SupabaseServiceKey
    Authorization = "Bearer $SupabaseServiceKey"
    Accept        = "application/json"
}

$query =
    "?select=id,project,agent,action,status,created_at,updated_at,command,logs,result_json&" +
    "project=eq.$([Uri]::EscapeDataString($Project))&" +
    "agent=eq.$([Uri]::EscapeDataString('jarvis_autoheal_worker'))&" +
    "action=eq.powershell&" +
    "order=created_at.desc&" +
    "limit=$Limit"

$uri = "$CommandsEndpoint$query"

Write-Host "Fetching auto-heal commands from: $uri"
$resp = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers

if (-not $resp) {
    Write-Host "No auto-heal commands found."
    Write-Host "=== Jarvis-ShowAutoHealSummary complete ==="
    exit 0
}

if ($resp -isnot [System.Array]) {
    $resp = @($resp)
}

# Project into a simple table
$rows = $resp | ForEach-Object {
    $handledAt = $null
    if ($_.result_json) {
        try {
            $r = $_.result_json | ConvertFrom-Json
            $handledAt = $r.executed_at_utc
        }
        catch { }
    }

    [pscustomobject]@{
        id         = $_.id
        status     = $_.status
        created_at = $_.created_at
        handled_at = $handledAt
        command    = $_.command
    }
}

Write-Host ""
Write-Host "Recent auto-heal executions:`n"
$rows | Format-Table -AutoSize

Write-Host ""
Write-Host "=== Jarvis-ShowAutoHealSummary complete ==="
