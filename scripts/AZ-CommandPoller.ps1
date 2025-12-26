# F:\AION-ZERO\scripts\AZ-CommandPoller.ps1

$ErrorActionPreference = "Stop"

$global:AZCommandAgent = "AZ-Command"

function Write-AZCommandEvent {
    param(
        [string]$Action,
        [string]$Status  = "success",
        [string]$Details = $null
    )

    & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
        -Project "System" `
        -Agent   $global:AZCommandAgent `
        -Action  $Action `
        -Status  $Status `
        -Details $Details
}

try {
    . "F:\AION-ZERO\scripts\Load-Supabase.ps1"

    Write-AZCommandEvent -Action "poll-start" -Status "running" -Details "Polling az_commands"

    $fetchUri = "$SBURL/rest/v1/az_commands" +
                "?select=id,command,project,target_agent,args" +
                "&status=eq.pending" +
                "&order=created_at.asc" +
                "&limit=1"

    $cmds = Invoke-RestMethod -Uri $fetchUri -Headers $SBHeaders -Method Get

    if (-not $cmds -or $cmds.Count -eq 0) {
        Write-AZCommandEvent -Action "no-pending" -Status "success" -Details "No pending commands"
        return
    }

    $cmd = if ($cmds -is [array]) { $cmds[0] } else { $cmds }

    $id     = $cmd.id
    $name   = $cmd.command
    $target = $cmd.target_agent
    $args   = $cmd.args

    Write-AZCommandEvent -Action "picked" -Status "running" -Details "id=$id command=$name target=$target"

    $updateUri = "$SBURL/rest/v1/az_commands?id=eq.$id"

    $headers = $SBHeaders.Clone()
    $headers["Content-Type"] = "application/json"
    $headers["Prefer"]       = "return=minimal"

    $bodyProcessing = @{
        status    = "processing"
        picked_at = (Get-Date).ToString("o")
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $updateUri -Headers $headers -Method Patch -Body $bodyProcessing | Out-Null

    $ok       = $true
    $errorMsg = $null

    # Extract linked task_id (if any)
    $taskIdFromArgs = $null
    if ($args) {
        try {
            $parsed = $args | ConvertFrom-Json
            if ($parsed.task_id) {
                $taskIdFromArgs = [int]$parsed.task_id
            }
        }
        catch { }
    }

    try {
        switch ($name) {
            "health_check" {
                & "F:\AION-ZERO\scripts\Invoke-AZHealth-Wrapper.ps1"
            }

            "snapshot_status" {
                & "F:\AION-ZERO\scripts\AZ-Snapshot.ps1"
            }

            "educonnect_health" {
                & "F:\AION-ZERO\scripts\Invoke-EduConnectHealth.ps1"
            }

            default {
                $ok       = $false
                $errorMsg = "Unknown command: $name"
            }
        }
    }
    catch {
        $ok       = $false
        $errorMsg = $_.Exception.Message
    }

    $finalStatus = if ($ok) { "done" } else { "error" }

    $bodyFinal = @{
        status       = $finalStatus
        completed_at = (Get-Date).ToString("o")
        error        = $errorMsg
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $updateUri -Headers $headers -Method Patch -Body $bodyFinal | Out-Null

    if ($ok -and $taskIdFromArgs) {
        $tasksUpdateUri = "$SBURL/rest/v1/az_tasks?id=eq.$taskIdFromArgs"

        $bodyTaskDone = @{
            status      = "done"
            last_run_at = (Get-Date).ToString("o")
        } | ConvertTo-Json

        Invoke-RestMethod -Uri $tasksUpdateUri -Headers $headers -Method Patch -Body $bodyTaskDone | Out-Null
    }

    if ($ok) {
        Write-AZCommandEvent -Action "execute" -Status "success" -Details "Command $name id=$id completed"
    }
    else {
        Write-AZCommandEvent -Action "execute-error" -Status "error" -Details "Command $name id=$id failed: $errorMsg"
    }
}
catch {
    $msg = $_.Exception.Message
    try {
        Write-AZCommandEvent -Action "fetch-error" -Status "error" -Details $msg
    }
    catch { }
    throw
}
