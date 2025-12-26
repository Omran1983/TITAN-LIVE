param(
    [string]$Project = "jarvis-hq"
)

Write-Host "Jarvis Command Worker starting for project '$Project'..." -ForegroundColor Cyan

# Load global envs (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, etc.)
& "F:\AION-ZERO\scripts\Use-ProjectEnv.ps1"

$supabaseUrl   = $env:SUPABASE_URL
$serviceRole   = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $supabaseUrl -or -not $serviceRole) {
    Write-Error "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set. Aborting worker."
    exit 1
}

$headers = @{
    apikey        = $serviceRole
    Authorization = "Bearer $serviceRole"
}

$base = "$supabaseUrl/rest/v1"

function Get-NextCommand {
    param(
        [string]$Project
    )

    $url = "$base/az_commands?project=eq.$Project&status=eq.queued&order=priority.desc,created_at.asc&limit=1"

    try {
        $resp = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

        if ($null -eq $resp) {
            return $null
        }

        if ($resp -is [System.Array]) {
            if ($resp.Count -gt 0) {
                return $resp[0]
            } else {
                return $null
            }
        }

        return $resp
    }
    catch {
        Write-Warning ("Get-NextCommand failed: {0}" -f $_.Exception.Message)
        return $null
    }
}

function Update-CommandStatus {
    param(
        [int]$Id,
        [string]$Status,
        [string]$Error = $null,
        [hashtable]$ExtraFields = $null
    )

    $payload = @{
        status = $Status
    }

    if ($Error) {
        $payload.error = $Error
    }

    if ($ExtraFields) {
        foreach ($k in $ExtraFields.Keys) {
            $payload[$k] = $ExtraFields[$k]
        }
    }

    $json = $payload | ConvertTo-Json -Depth 8
    $url  = "$base/az_commands?id=eq.$Id"

    try {
        Invoke-RestMethod -Uri $url -Headers $headers -Method Patch -Body $json | Out-Null
    }
    catch {
        Write-Warning ("Update-CommandStatus failed for id={0}: {1}" -f $Id, $_.Exception.Message)
    }
}

while ($true) {
    Write-Host "Polling for queued commands..." -ForegroundColor DarkGray
    $cmd = Get-NextCommand -Project $Project

    if (-not $cmd) {
        Start-Sleep -Seconds 5
        continue
    }

    $id         = $cmd.id
    $toolName   = $cmd.command
    $args       = $cmd.args

    Write-Host "Picked command id=$id command=$toolName" -ForegroundColor Yellow
    $nowIso = (Get-Date).ToString("o")

    Update-CommandStatus -Id $id -Status "running" -ExtraFields @{
        picked_at = $nowIso
        agent     = "jarvis-hq-api"
        action    = "run"
    }

    try {
        $stdout = ""
        $stderr = ""

        switch ($toolName) {

            "ps.run" {
                $psCommand = $args.command
                if (-not $psCommand) {
                    throw "Missing args.command for ps.run"
                }

                Write-Host "Executing ps.run: $psCommand" -ForegroundColor Cyan
                $out = powershell -NoProfile -ExecutionPolicy Bypass -Command $psCommand 2>&1
                $stdout = ($out | Out-String)
            }

            "backup.snapshot" {
                $label = $args.label
                if (-not $label) {
                    $label = "jarvis-core"
                }

                $scriptPath = "F:\AION-ZERO\scripts\Jarvis-BackupSnapshot.ps1"
                if (-not (Test-Path $scriptPath)) {
                    throw "Backup script not found at $scriptPath"
                }

                Write-Host "Executing backup.snapshot with label '$label'..." -ForegroundColor Cyan
                $out = powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath -Label $label 2>&1
                $stdout = ($out | Out-String)
            }

            "reachx.env.apply" {
                $projectRoot = $args.project_root
                if (-not $projectRoot) {
                    $projectRoot = "F:\ReachX-AI"
                }

                $scriptPath = "F:\AION-ZERO\scripts\Jarvis-ReachX-EnvApply.ps1"
                if (-not (Test-Path $scriptPath)) {
                    throw "ReachX env apply script not found at $scriptPath"
                }

                Write-Host "Executing reachx.env.apply for '$projectRoot'..." -ForegroundColor Cyan
                $out = powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath -ProjectRoot $projectRoot 2>&1
                $stdout = ($out | Out-String)
            }

                    "reachx.ui.launch" {
            # args.project_root is optional; default to F:\ReachX-AI
            $projectRoot = $null
            if ($args -and $args.PSObject.Properties.Name -contains "project_root") {
                $projectRoot = $args.project_root
            }
            if (-not $projectRoot) {
                $projectRoot = "F:\ReachX-AI"
            }

            Write-Host "Executing reachx.ui.launch for '$projectRoot'..."
            & "F:\AION-ZERO\scripts\ReachX-LaunchUI.ps1" -ProjectRoot $projectRoot
        }

            default {
                throw "Unknown tool: $toolName"
            }
        }

        $payloadJson = @{
            executed_at = (Get-Date).ToString("o")
            stdout      = $stdout
            stderr      = $stderr
        }

        Update-CommandStatus -Id $id -Status "done" -ExtraFields @{
            completed_at = (Get-Date).ToString("o")
            payload_json = $payloadJson
            error        = $null
        }

        Write-Host "Command id=$id completed successfully." -ForegroundColor Green
    }
    catch {
        $errText = $_.Exception.ToString()
        Write-Warning ("Command id={0} failed: {1}" -f $id, $errText)

        Update-CommandStatus -Id $id -Status "error" -Error $errText -ExtraFields @{
            completed_at = (Get-Date).ToString("o")
        }
    }
}
