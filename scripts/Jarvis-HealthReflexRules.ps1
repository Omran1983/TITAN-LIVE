param(
    [string]$Project = "AION-ZERO",

    # Supabase base URL and key from env
    [string]$SupabaseUrl        = $env:SUPABASE_URL,
    [string]$SupabaseServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY,

    # Tables
    [string]$HealthTable   = "az_health_snapshots",
    [string]$CommandsTable = "az_commands"
)

$ErrorActionPreference = "Stop"

# --- Resolve script dir + load .env ---

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile   = Join-Path $ScriptDir "Jarvis-HealthReflexRules.log"

$loadEnvPath = Join-Path $ScriptDir "Jarvis-LoadEnv.ps1"
if (Test-Path $loadEnvPath) {
    try {
        & $loadEnvPath | Out-Null
    }
    catch {
        Write-Host "HealthReflexRules: Failed to load env: $($_.Exception.Message)"
    }
}

# Refresh Supabase config from env if not passed
if (-not $SupabaseUrl)        { $SupabaseUrl        = $env:SUPABASE_URL }
if (-not $SupabaseServiceKey) { $SupabaseServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY }

function Write-HealthReflexLog {
    param([string]$Message)

    $ts  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $msg = "HealthReflex [$ts] $Message"
    Write-Host $msg
    if ($LogFile -and $LogFile.Trim() -ne "") {
        try {
            Add-Content -LiteralPath $LogFile -Value $msg
        }
        catch {
            Write-Host "HealthReflex [$ts] Failed to write log: $($_.Exception.Message)"
        }
    }
}

if (-not $SupabaseUrl -or -not $SupabaseServiceKey) {
    Write-HealthReflexLog "ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set. Aborting."
    return
}

$HealthEndpoint   = "$SupabaseUrl/rest/v1/$HealthTable"
$CommandsEndpoint = "$SupabaseUrl/rest/v1/$CommandsTable"

$CommonHeaders = @{
    "apikey"        = $SupabaseServiceKey
    "Authorization" = "Bearer $SupabaseServiceKey"
    "Content-Type"  = "application/json"
    "Prefer"        = "return=representation"
}

Write-HealthReflexLog "=== Jarvis-HealthReflexRules start ==="
Write-HealthReflexLog "HealthEndpoint   = $HealthEndpoint"
Write-HealthReflexLog "CommandsEndpoint = $CommandsEndpoint"

# --- Fetch latest health snapshot ---

$healthQuery = "?select=*&order=created_at.desc&limit=1"

try {
    $latest = Invoke-RestMethod -Method Get -Uri ($HealthEndpoint + $healthQuery) -Headers $CommonHeaders
}
catch {
    Write-HealthReflexLog "ERROR fetching latest health snapshot: $($_.Exception.Message)"
    return
}

if ($null -eq $latest) {
    Write-HealthReflexLog "No health snapshots found. Exiting."
    return
}

if ($latest -isnot [System.Array]) {
    $latest = @($latest)
}

if ($latest.Count -eq 0) {
    Write-HealthReflexLog "No health snapshots found (empty array). Exiting."
    return
}

$h = $latest[0]

$hs_id      = $h.id
$hs_status  = $h.overall_status
$hs_queue   = $h.queue_depth
$hs_errors  = $h.errors_last_10m
$hs_latency = $h.avg_latency_ms

Write-HealthReflexLog "Latest health: id=$hs_id status=$hs_status queue=$hs_queue errors=$hs_errors latency=$hs_latency"

# --- Decide which rules fire ---

$rulesToFire = @()

if ($hs_status -ne "ok") {
    $rulesToFire += [pscustomobject]@{
        rule    = "Overall status not ok"
        trigger = "status_not_ok"
    }
}

if ($hs_errors -ge 5) {
    $rulesToFire += [pscustomobject]@{
        rule    = "Error rate high"
        trigger = "error_rate_high"
    }
}

if ($hs_queue -ge 50 -or $hs_queue -eq 999) {
    $rulesToFire += [pscustomobject]@{
        rule    = "Queue depth high"
        trigger = "queue_depth_high"
    }
}

if ($rulesToFire.Count -eq 0) {
    Write-HealthReflexLog "No reflex rules fired for this snapshot. Exiting."
    Write-HealthReflexLog "=== Jarvis-HealthReflexRules end (no-op) ==="
    return
}

Write-HealthReflexLog ("Rules fired: " + ($rulesToFire | ForEach-Object { "$($_.rule)/$($_.trigger)" } -join ", "))

# --- Helper: enqueue a command row ---

function New-CommandRow {
    param(
        [string]$Project,
        [string]$Agent,
        [string]$Action,
        [string]$Status,
        [hashtable]$Args,
        [string]$CommandText = $null,
        [string]$Logs        = $null
    )

    $body = @{
        project = $Project
        agent   = $Agent
        action  = $Action
        status  = $Status
        args    = $Args
    }

    if ($null -ne $CommandText -and $CommandText.Trim() -ne "") {
        $body["command"] = $CommandText
    }
    if ($null -ne $Logs -and $Logs.Trim() -ne "") {
        $body["logs"] = $Logs
    }

    $json = $body | ConvertTo-Json -Depth 10

    Write-HealthReflexLog "POST $CommandsEndpoint"
    Write-HealthReflexLog "Body: $json"

    try {
        $resp = Invoke-RestMethod -Method Post -Uri $CommandsEndpoint -Headers $CommonHeaders -Body $json
        if ($resp -is [System.Array]) { $resp = $resp[0] }
        Write-HealthReflexLog "Inserted command id=$($resp.id) agent=$($resp.agent) action=$($resp.action) status=$($resp.status)"
    }
    catch {
        Write-HealthReflexLog "ERROR inserting command: $($_.Exception.Message)"
    }
}

# --- Default auto-heal PowerShell script ---

$autoHealPs = @'
Write-Host "AUTOHEAL: restarting core Jarvis workers due to health incident";
try {
    schtasks.exe /Run /TN "Jarvis-NotifyWorker" | Out-Null
} catch {
    Write-Host "AUTOHEAL: Failed to run Jarvis-NotifyWorker: $($_.Exception.Message)"
}
try {
    schtasks.exe /Run /TN "Jarvis-ReflexWorker" | Out-Null
} catch {
    Write-Host "AUTOHEAL: Failed to run Jarvis-ReflexWorker: $($_.Exception.Message)"
}
'@

# --- For each rule: create reflex, notify, and auto-heal commands ---

foreach ($r in $rulesToFire) {
    $rule    = $r.rule
    $trigger = $r.trigger

    # 1) Reflex command (for history / ShowReflexSummary)
    $reflexArgs = @{
        rule         = $rule
        trigger      = $trigger
        snapshot_id  = $hs_id
        queue_depth  = $hs_queue
        errors_10min = $hs_errors
        latency_ms   = $hs_latency
    }

    New-CommandRow -Project $Project `
                   -Agent "jarvis_reflex_worker" `
                   -Action "reflex" `
                   -Status "queued" `
                   -Args $reflexArgs `
                   -Logs "Reflex rule '$rule' fired by trigger '$trigger' for snapshot $hs_id."

    # 2) Notify command (Telegram alert)
    $notifyMessage = "HEALTH ALERT [$Project] Rule '$rule' fired (trigger=$trigger) on snapshot $hs_id.`n" +
                     "Status=$hs_status, Queue=$hs_queue, Errors10m=$hs_errors, LatencyMs=$hs_latency"

    $notifyArgs = @{
        message     = $notifyMessage
        rule        = $rule
        trigger     = $trigger
        snapshot_id = $hs_id
    }

    New-CommandRow -Project $Project `
                   -Agent "jarvis_notify_worker" `
                   -Action "notify" `
                   -Status "queued" `
                   -Args $notifyArgs `
                   -Logs "Queued notify for rule '$rule' / trigger '$trigger'."

    # 3) Auto-heal command (handled by Jarvis-AutoHealWorker)
    $autoHealArgs = @{
        rule        = $rule
        trigger     = $trigger
        snapshot_id = $hs_id
        strategy    = "restart_core_workers"
    }

    New-CommandRow -Project $Project `
                   -Agent "jarvis_autoheal_worker" `
                   -Action "powershell" `
                   -Status "queued" `
                   -Args $autoHealArgs `
                   -CommandText $autoHealPs `
                   -Logs "Queued auto-heal (restart core workers) for rule '$rule' / trigger '$trigger'."
}

Write-HealthReflexLog "=== Jarvis-HealthReflexRules end ==="
