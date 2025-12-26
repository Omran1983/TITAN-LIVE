param(
    [string]$Project = "AION-ZERO",
    [string]$AgentName = "jarvis_autoheal_worker",
    [int]$PollSeconds = 30,
    [string]$SupabaseUrl = $env:SUPABASE_URL,
    [string]$SupabaseServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY,
    [string]$CommandsTable = "az_commands"
)

$ErrorActionPreference = "Stop"

# --- Resolve script directory ---
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile   = Join-Path $ScriptDir "Jarvis-AutoHealWorker.log"

# --- Load .env automatically ---
$loadEnvPath = Join-Path $ScriptDir "Jarvis-LoadEnv.ps1"
if (Test-Path $loadEnvPath) {
    try { & $loadEnvPath | Out-Null }
    catch { Write-Host "AutoHealWorker: Failed to load env: $($_.Exception.Message)" }
}

# Refresh values if LoadEnv updated them
if (-not $SupabaseUrl)        { $SupabaseUrl = $env:SUPABASE_URL }
if (-not $SupabaseServiceKey) { $SupabaseServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY }

# --- Logging helper ---
function Write-AutoHealLog {
    param([string]$Message)
    $ts  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $msg = "AutoHealWorker [$ts] $Message"
    Write-Host $msg

    try { Add-Content -LiteralPath $LogFile -Value $msg }
    catch { Write-Host "AutoHealWorker [$ts] Failed to write log file: $($_.Exception.Message)" }
}

# --- Validate config ---
if (-not $SupabaseUrl -or -not $SupabaseServiceKey) {
    Write-AutoHealLog "ERROR: Missing Supabase config. Aborting."
    exit 1
}

$CommandsEndpoint = "$SupabaseUrl/rest/v1/$CommandsTable"
Write-AutoHealLog "CommandsEndpoint = $CommandsEndpoint"

$CommonHeaders = @{
    "apikey"        = $SupabaseServiceKey
    "Authorization" = "Bearer $SupabaseServiceKey"
    "Content-Type"  = "application/json"
    "Prefer"        = "return=representation"
}

# Store for helper functions
$script:CommandsEndpoint = $CommandsEndpoint
$script:CommonHeaders    = $CommonHeaders

# --- Retrieve next queued auto-heal command ---
function Get-NextAutoHealCommand {
    param([string]$Project)

    $query = "?select=*&" +
             "project=eq.$([Uri]::EscapeDataString($Project))&" +
             "agent=eq.jarvis_autoheal_worker&" +
             "action=eq.powershell&" +
             "status=eq.queued&" +
             "order=created_at.asc&" +
             "limit=1"

    $url = "$script:CommandsEndpoint$query"

    Write-AutoHealLog "Polling: $url"

    try { $resp = Invoke-RestMethod -Method Get -Uri $url -Headers $script:CommonHeaders }
    catch {
        Write-AutoHealLog "ERROR GET: $($_.Exception.Message)"
        return $null
    }

    if ($null -eq $resp) { return $null }
    if ($resp -isnot [System.Array]) { $resp = @($resp) }
    if ($resp.Count -eq 0) { return $null }

    return $resp[0]
}

# --- Claim command row ---
function Claim-AutoHealCommand {
    param($Command, [string]$AgentName)

    if ($null -eq $Command -or -not $Command.id) { return $null }

    $id  = $Command.id
    $now = (Get-Date).ToUniversalTime().ToString("o")

    $body = @{
        status     = "running"
        picked_at  = $now
        updated_at = $now
        agent      = $AgentName
    } | ConvertTo-Json -Depth 5

    $url = "$script:CommandsEndpoint?id=eq.$id&status=eq.queued"

    Write-AutoHealLog "Claiming id=$id"
    Write-AutoHealLog "PATCH $url"

    try { $resp = Invoke-RestMethod -Method Patch -Uri $url -Headers $script:CommonHeaders -Body $body }
    catch {
        Write-AutoHealLog "ERROR claim: $($_.Exception.Message)"
        return $null
    }

    if ($null -eq $resp) { return $null }
    if ($resp -isnot [System.Array]) { $resp = @($resp) }
    if ($resp.Count -eq 0) { return $null }

    Write-AutoHealLog "Claimed id=$id"
    return $resp[0]
}

# --- Mark success ---
function Complete-AutoHealCommand {
    param($Command, [string]$ResultMessage, $ResultData)

    $id  = $Command.id
    $now = (Get-Date).ToUniversalTime().ToString("o")

    $body = @{
        status       = "done"
        completed_at = $now
        updated_at   = $now
        logs         = $ResultMessage
        result_json  = ($ResultData | ConvertTo-Json -Depth 10)
    } | ConvertTo-Json -Depth 10

    $url = "$script:CommandsEndpoint?id=eq.$id"

    Write-AutoHealLog "Marking id=$id done"

    try { Invoke-RestMethod -Method Patch -Uri $url -Headers $script:CommonHeaders -Body $body }
    catch { Write-AutoHealLog "ERROR complete: $($_.Exception.Message)" }
}

# --- Mark failure ---
function Fail-AutoHealCommand {
    param($Command, [string]$ErrorMessage)

    $id  = $Command.id
    $now = (Get-Date).ToUniversalTime().ToString("o")

    $body = @{
        status       = "error"
        updated_at   = $now
        completed_at = $now
        logs         = $ErrorMessage
        error        = $ErrorMessage
    } | ConvertTo-Json -Depth 10

    $url = "$script:CommandsEndpoint?id=eq.$id"

    Write-AutoHealLog "Marking id=$id ERROR"

    try { Invoke-RestMethod -Method Patch -Uri $url -Headers $script:CommonHeaders -Body $body }
    catch { Write-AutoHealLog "ERROR fail: $($_.Exception.Message)" }
}

# --- Run PowerShell auto-heal command ---
function Handle-AutoHealCommand {
    param($Command)

    $id      = $Command.id
    $psText  = $Command.command
    $project = $Command.project

    if (-not $psText -or $psText.Trim() -eq "") {
        throw "Auto-heal command id=$id has empty command text."
    }

    Write-AutoHealLog "Running id=$id → $psText"

    $output = ""
    $success = $false

    try {
        $output = (Invoke-Expression $psText 2>&1 | Out-String)
        $success = $true
    }
    catch {
        $output = "$output`nERROR: $($_.Exception.Message)"
        $success = $false
    }

    $result = [pscustomobject]@{
        project          = $project
        command_id       = $id
        powershell       = $psText
        output           = $output
        success          = $success
        executed_at_utc  = (Get-Date).ToUniversalTime().ToString("o")
        executed_on_host = $env:COMPUTERNAME
        handled_by       = $AgentName
    }

    if ($success) {
        Complete-AutoHealCommand -Command $Command -ResultMessage "Success." -ResultData $result
    }
    else {
        Fail-AutoHealCommand -Command $Command -ErrorMessage $output
    }
}

# --- MAIN EXECUTION (single run, safe for scheduler) ---

Write-AutoHealLog "=== AutoHealWorker start ==="

$cmd = Get-NextAutoHealCommand -Project $Project

if ($null -eq $cmd) {
    Write-AutoHealLog "No auto-heal commands. Exiting."
    Write-AutoHealLog "=== AutoHealWorker end ==="
    exit 0
}

$claimed = Claim-AutoHealCommand -Command $cmd -AgentName $AgentName
if ($null -eq $claimed) {
    Write-AutoHealLog "Unable to claim. Exiting."
    exit 0
}

try { Handle-AutoHealCommand -Command $claimed }
catch {
    Fail-AutoHealCommand -Command $claimed -ErrorMessage $_.Exception.Message
}

Write-AutoHealLog "=== AutoHealWorker end ==="
exit 0
