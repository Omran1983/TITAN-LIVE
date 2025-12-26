param(
    [string]$Environment       = "dev",
    [int]$PollIntervalSeconds  = 20
)

Write-Host "=== Jarvis Command Poller starting (env=$Environment) ===" -ForegroundColor Cyan

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Error "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set."
    exit 1
}

$baseUrl = $env:SUPABASE_URL.Trim()
$baseUrl = $baseUrl -replace "/+$",""
$apiKey  = $env:SUPABASE_SERVICE_ROLE_KEY

$cmdUrl  = $baseUrl + "/rest/v1/jarvis_commands"

$headers = @{
    "apikey"        = $apiKey
    "Authorization" = "Bearer $apiKey"
    "Content-Type"  = "application/json"
}

$submitScript = "F:\ReachX-AI\scripts\ReachX-SubmitRemoteJob.ps1"
if (-not (Test-Path $submitScript)) {
    Write-Error "Submit script not found at $submitScript"
    exit 1
}

function Get-NextJarvisCommand {
    $uri = $cmdUrl + "?environment=eq." + $Environment + "&status=eq.queued&order=created_at.asc&limit=1"
    Write-Host "DEBUG Jarvis cmd URI: [$uri]" -ForegroundColor DarkGray

    try {
        $cmds = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction Stop
        if ($cmds -and $cmds.Count -gt 0) { return $cmds[0] }
        return $null
    } catch {
        Write-Error "Error polling jarvis_commands: $_"
        return $null
    }
}

function Update-JarvisCommandStatus {
    param(
        [long]$CmdId,
        [string]$Status,
        [long]$LinkedJobId = $null,
        [string]$LastError = $null,
        [bool]$SetStarted  = $false,
        [bool]$SetFinished = $false
    )

    $patch = @{}
    $patch["status"] = $Status

    $nowIso = (Get-Date).ToString("o")
    if ($SetStarted)  { $patch["started_at"]  = $nowIso }
    if ($SetFinished) { $patch["finished_at"] = $nowIso }

    if ($LinkedJobId) { $patch["linked_job_id"] = $LinkedJobId }
    if ($LastError)   { $patch["last_error"]    = $LastError }

    $body = $patch | ConvertTo-Json -Depth 5

    $uri = $cmdUrl + "?id=eq." + $CmdId

    Write-Host "DEBUG update Jarvis cmd ${CmdId}: [$uri]" -ForegroundColor DarkGray
    Write-Host "DEBUG patch: $body" -ForegroundColor DarkGray

    $localHeaders = $headers.Clone()
    $localHeaders["Prefer"] = "return=representation"

    try {
        $resp = Invoke-RestMethod -Method Patch -Uri $uri -Headers $localHeaders -Body $body -ErrorAction Stop
        return $resp
    } catch {
        Write-Error "Failed to update jarvis_commands ${CmdId}: $_"
    }
}

function Handle-JarvisCommand {
    param(
        $cmdRow
    )

    $cmdId   = $cmdRow.id
    $intent  = $cmdRow.intent
    $payload = $cmdRow.payload_json

    Write-Host "Handling Jarvis command id=$cmdId intent=$intent" -ForegroundColor Yellow

    Update-JarvisCommandStatus -CmdId $cmdId -Status "running" -SetStarted $true | Out-Null

    $errMsg = $null

    try {
        switch ($intent) {
            "refresh_machine_profiles" {
                $remoteCmd = 'F:\ReachX-AI\scripts\ReachX-Report-MachineProfile-ToSupabase.ps1 -Environment "dev"'
                & $submitScript -Environment "dev" -MinCpuScore 8 -MinMemoryScore 8 -CommandText $remoteCmd | Out-Null
            }

            "append_heartbeat_log" {
                $remoteCmd = 'Add-Content -Path "F:\ReachX-AI\remote-test-log.txt" -Value "Jarvis heartbeat at $(Get-Date)"'
                & $submitScript -Environment "dev" -MinCpuScore 8 -MinMemoryScore 8 -CommandText $remoteCmd | Out-Null
            }

            "run_powershell" {
                if (-not $payload -or -not $payload.command_text) {
                    throw "payload_json.command_text is required for run_powershell"
                }
                $remoteCmd = $payload.command_text
                & $submitScript -Environment "dev" -MinCpuScore 8 -MinMemoryScore 8 -CommandText $remoteCmd | Out-Null
            }

            default {
                throw "Unknown intent: $intent"
            }
        }
    } catch {
        $errMsg = $_.ToString()
    }

    if ($errMsg) {
        Write-Host "Jarvis command $cmdId failed: $errMsg" -ForegroundColor Red
        Update-JarvisCommandStatus -CmdId $cmdId -Status "failed" -LastError $errMsg -SetFinished $true | Out-Null
    } else {
        Write-Host "Jarvis command $cmdId processed." -ForegroundColor Green
        Update-JarvisCommandStatus -CmdId $cmdId -Status "done" -SetFinished $true | Out-Null
    }
}

while ($true) {
    Write-Host "[$(Get-Date -Format 'u')] Jarvis polling for commands..." -ForegroundColor DarkGray
    $cmd = Get-NextJarvisCommand

    if ($cmd) {
        Handle-JarvisCommand -cmdRow $cmd
    } else {
        Start-Sleep -Seconds $PollIntervalSeconds
    }
}
