param()

$ErrorActionPreference = "Stop"

# -------- Config --------
$PollSeconds = 20
if ($env:JARVIS_POLL_INTERVAL_SECONDS) {
    $tmp = 0
    if ([int]::TryParse($env:JARVIS_POLL_INTERVAL_SECONDS, [ref]$tmp) -and $tmp -gt 0) {
        $PollSeconds = $tmp
    }
}

# Hard-code the table name so it CANNOT be empty
$commandsTable = "az_commands"

# -------- Logging helper --------
function Write-Log {
    param(
        [string]$Message
    )
    $ts   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$ts - $Message"

    $logDir = $env:JARVIS_LOG_DIR
    if ([string]::IsNullOrWhiteSpace($logDir)) {
        $logDir = "/logs"
    }

    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $logPath = Join-Path $logDir "command-agent.log"
    $line | Tee-Object -FilePath $logPath -Append | Out-Host
}

# -------- Env + Supabase setup --------
$supabaseUrl = $env:SUPABASE_URL
$serviceKey  = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $supabaseUrl -or -not $serviceKey) {
    Write-Log "FATAL: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set. Exiting."
    exit 1
}

$headers = @{
    "apikey"        = $serviceKey
    "Authorization" = "Bearer $serviceKey"
    "Content-Type"  = "application/json"
}

Write-Log ("Jarvis-CommandAgent started. Polling table '{0}' every {1} seconds." -f $commandsTable, $PollSeconds)
Write-Log ("Using Supabase URL: {0}" -f $supabaseUrl)

# -------- Main loop --------
while ($true) {
    $id = $null
    try {
        # 1) Get next queued command
        $uri = "$supabaseUrl/rest/v1/$commandsTable?status=eq.queued&order=created_at.asc&limit=1"
        Write-Log ("Polling: {0}" -f $uri)

        $cmds = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers

        if (-not $cmds -or $cmds.Count -eq 0) {
            Start-Sleep -Seconds $PollSeconds
            continue
        }

        $cmd = $cmds[0]
        $id  = $cmd.id
        $commandText = $cmd.command

        Write-Log ("Picked command id={0} cmd=""{1}""" -f $id, $commandText)

        # 2) Mark as running
        $patchUri = "$supabaseUrl/rest/v1/$commandsTable?id=eq.$id"
        $bodyRunning = @{
            status     = "running"
            started_at = (Get-Date).ToString("o")
        } | ConvertTo-Json

        Invoke-RestMethod -Method Patch -Uri $patchUri -Headers $headers -Body $bodyRunning | Out-Null

        # 3) Execute locally
        Write-Log "Executing command via Invoke-Expression..."
        $result = Invoke-Expression $commandText 2>&1 | Out-String

        # 4) Mark as done
        $bodyDone = @{
            status      = "done"
            finished_at = (Get-Date).ToString("o")
            logs        = $result
        } | ConvertTo-Json

        Invoke-RestMethod -Method Patch -Uri $patchUri -Headers $headers -Body $bodyDone | Out-Null
        Write-Log ("Command id={0} completed." -f $id)
    }
    catch {
        $err = $_.Exception.Message
        Write-Log ("ERROR: {0}" -f $err)

        if ($id) {
            try {
                $bodyErr = @{
                    status      = "error"
                    finished_at = (Get-Date).ToString("o")
                    logs        = $err
                } | ConvertTo-Json

                $patchUri = "$supabaseUrl/rest/v1/$commandsTable?id=eq.$id"
                Invoke-RestMethod -Method Patch -Uri $patchUri -Headers $headers -Body $bodyErr | Out-Null
            }
            catch {
                $inner = $_.Exception.Message
                Write-Log ("ERROR updating Supabase for failed command id={0}: {1}" -f $id, $inner)
            }
        }
    }

    Start-Sleep -Seconds $PollSeconds
}
