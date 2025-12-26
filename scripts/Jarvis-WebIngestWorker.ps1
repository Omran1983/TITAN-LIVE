Write-Host "=== Jarvis-WebIngestWorker ===" -ForegroundColor Cyan

# Resolve script directory
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir  = Split-Path -Parent $scriptPath

Write-Host "ScriptDir: $scriptDir" -ForegroundColor DarkGray

# Load environment
$envScript = Join-Path $scriptDir "Jarvis-LoadEnv.ps1"
if (Test-Path $envScript) {
    . $envScript
    Write-Host "Loaded environment from Jarvis-LoadEnv.ps1." -ForegroundColor DarkGray
} else {
    Write-Host "ERROR - Jarvis-LoadEnv.ps1 not found at $envScript" -ForegroundColor Red
    exit 1
}

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "ERROR - SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is not set in environment." -ForegroundColor Red
    exit 1
}

$baseUrl    = $env:SUPABASE_URL.TrimEnd('/')
$serviceKey = $env:SUPABASE_SERVICE_ROLE_KEY

$headers = @{
    apikey         = $serviceKey
    Authorization  = "Bearer $serviceKey"
    Accept         = "application/json"
    "Content-Type" = "application/json"
}

# Fetch oldest queued command for this agent
$commandsUrl = "$baseUrl/rest/v1/az_commands?select=*&agent=eq.jarvis_web_ingest_worker&status=eq.queued&order=created_at.asc&limit=1"
Write-Host "Commands URL: $commandsUrl" -ForegroundColor DarkGray

try {
    $resp = Invoke-RestMethod -Method Get -Uri $commandsUrl -Headers $headers
} catch {
    Write-Host ("ERROR - Failed to fetch commands: {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}

if (-not $resp -or $resp.Count -eq 0) {
    Write-Host "No queued commands for jarvis_web_ingest_worker. Exiting." -ForegroundColor DarkGray
    exit 0
}

$cmd = if ($resp -is [System.Array]) { $resp[0] } else { $resp }

$cmdId   = $cmd.id
$agent   = $cmd.agent
$action  = $cmd.action

# Project fallback: args.project -> command.project -> "AION-ZERO"
$project = if ($cmd.args -and $cmd.args.project) {
    $cmd.args.project
} elseif ($cmd.project) {
    $cmd.project
} else {
    "AION-ZERO"
}

$url = $null
if ($cmd.args -and $cmd.args.url) {
    $url = $cmd.args.url
}

Write-Host "Processing command id=$cmdId agent=$agent action=$action project=$project url=$url" -ForegroundColor Cyan

function Update-CommandStatus {
    param(
        [int]$Id,
        [string]$Status,
        [string]$ExtraLogs
    )

    $patchUrl = "$baseUrl/rest/v1/az_commands?id=eq.$Id"

    $existingLogs = ""
    if ($cmd.logs) { $existingLogs = [string]$cmd.logs }

    $combinedLogs = $existingLogs
    if ($ExtraLogs) {
        if ($combinedLogs) { $combinedLogs += "`n" }
        $combinedLogs += $ExtraLogs
    }

    $bodyObj = @{ status = $Status }
    if ($combinedLogs) { $bodyObj.logs = $combinedLogs }

    $bodyJson = $bodyObj | ConvertTo-Json -Compress

    try {
        Invoke-RestMethod -Method Patch -Uri $patchUrl -Headers $headers -Body $bodyJson
        Write-Host ("Updated command {0} -> {1}" -f $Id, $Status) -ForegroundColor DarkGray
    } catch {
        $errMsg = $_.Exception.Message
        Write-Host ("ERROR - Failed to update command {0} - {1}" -f $Id, $errMsg) -ForegroundColor Red
    }
}

if (-not $url) {
    Write-Host "ERROR - Command has no args.url, cannot ingest." -ForegroundColor Red
    Update-CommandStatus -Id $cmdId -Status "error" -ExtraLogs "WebIngestWorker: missing args.url"
    exit 1
}

$webIngestScript = Join-Path $scriptDir "Jarvis-WebIngest.ps1"
if (-not (Test-Path $webIngestScript)) {
    Write-Host "ERROR - Jarvis-WebIngest.ps1 not found at $webIngestScript" -ForegroundColor Red
    Update-CommandStatus -Id $cmdId -Status "error" -ExtraLogs "WebIngestWorker: Jarvis-WebIngest.ps1 not found"
    exit 1
}

try {
    Write-Host "Calling Jarvis-WebIngest.ps1 ..." -ForegroundColor DarkCyan
    & $webIngestScript -Project $project -Url $url

    Update-CommandStatus -Id $cmdId -Status "done" -ExtraLogs "WebIngestWorker: ingested $url for project=$project"
    Write-Host "=== Jarvis-WebIngestWorker end (success) ===" -ForegroundColor Cyan
    exit 0
} catch {
    $msg = "WebIngestWorker: error while ingesting $url - $($_.Exception.Message)"
    Write-Host ("ERROR - {0}" -f $msg) -ForegroundColor Red
    Update-CommandStatus -Id $cmdId -Status "error" -ExtraLogs $msg
    exit 1
}
