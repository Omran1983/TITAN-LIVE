param(
    [string]$Project    = "AION-ZERO",
    [int]$Limit         = 20,
    [string]$SupabaseUrl        = $env:SUPABASE_URL,
    [string]$SupabaseServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY,
    [string]$CommandsTable      = "az_commands"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$loadEnvPath = Join-Path $ScriptDir "Jarvis-LoadEnv.ps1"
if (Test-Path $loadEnvPath) {
    try { & $loadEnvPath | Out-Null } catch {}
}

if (-not $SupabaseUrl)        { $SupabaseUrl        = $env:SUPABASE_URL }
if (-not $SupabaseServiceKey) { $SupabaseServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY }

$CommandsEndpoint = "$SupabaseUrl/rest/v1/$CommandsTable"

$CommonHeaders = @{
    "apikey"        = $SupabaseServiceKey
    "Authorization" = "Bearer $SupabaseServiceKey"
    "Accept"        = "application/json"
}

Write-Host "=== Jarvis-ShowAutoHealHistory ==="
Write-Host "Project = $Project, Limit = $Limit"
Write-Host "Endpoint = $CommandsEndpoint"
Write-Host ""

# Only show auto-heal commands
$query =
    "?select=id,project,agent,action,status,created_at,updated_at,args,logs" +
    "&project=eq.$([Uri]::EscapeDataString($Project))" +
    "&agent=eq.$([Uri]::EscapeDataString('jarvis_autoheal_worker'))" +
    "&action=eq.powershell" +
    "&order=created_at.desc" +
    "&limit=$Limit"

try {
    $resp = Invoke-RestMethod -Method Get -Uri ($CommandsEndpoint + $query) -Headers $CommonHeaders
}
catch {
    Write-Host "ERROR fetching auto-heal history: $($_.Exception.Message)"
    return
}

if ($null -eq $resp) {
    Write-Host "No auto-heal commands found."
    return
}

if ($resp -isnot [System.Array]) { $resp = @($resp) }

if ($resp.Count -eq 0) {
    Write-Host "No auto-heal commands found."
    return
}

$rows = $resp | Select-Object `
    id,
    project,
    agent,
    action,
    status,
    created_at,
    @{Name="rule";    Expression = { $_.args.rule } },
    @{Name="trigger"; Expression = { $_.args.trigger } },
    @{Name="summary"; Expression = {
        if ($_.logs -and $_.logs.Length -gt 60) {
            $_.logs.Substring(0,60) + "..."
        } else {
            $_.logs
        }
    }}

$rows | Format-Table -AutoSize

Write-Host ""
Write-Host "=== Jarvis-ShowAutoHealHistory complete ==="
