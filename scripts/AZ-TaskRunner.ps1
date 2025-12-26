# F:\AION-ZERO\scripts\AZ-TaskRunner.ps1

$ErrorActionPreference = "Stop"

$global:AZTasksAgent = "AZ-Tasks"

function Write-AZTasksEvent {
    param(
        [string]$Action,
        [string]$Status  = "success",
        [string]$Details = $null
    )

    & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
        -Project "System" `
        -Agent   $global:AZTasksAgent `
        -Action  $Action `
        -Status  $Status `
        -Details $Details
}

try {
    . "F:\AION-ZERO\scripts\Load-Supabase.ps1"

    Write-AZTasksEvent -Action "tick-start" -Status "running" -Details "Selecting pending tasks"

    # NOTE: we use last_run (NOT last_run_at)
    $tasksUri = "$SBURL/rest/v1/az_tasks" +
                "?select=id,project_id,title,status,kind,owner,priority,created_at,last_run" +
                "&status=eq.pending" +
                "&order=priority.asc,created_at.asc" +
                "&limit=10"

    $pending = Invoke-RestMethod -Uri $tasksUri -Headers $SBHeaders -Method Get

    if (-not $pending -or $pending.Count -eq 0) {
        Write-AZTasksEvent -Action "no-pending-tasks" -Status "success" -Details "No pending tasks in az_tasks"
        return
    }

    if ($pending -isnot [array]) {
        $pending = @($pending)
    }

    $task = $null

    foreach ($t in $pending) {
        if ($t.kind -eq "infra" -and $t.title -like "EduConnect: Cloudflare Worker health*") {
            $task = $t
            break
        }
    }

    if (-not $task) {
        Write-AZTasksEvent -Action "no-dispatchable-task" -Status "success" -Details "Pending tasks exist but none with handler yet"
        return
    }

    $taskId    = $task.id
    $taskTitle = $task.title

    Write-AZTasksEvent -Action "dispatch" -Status "running" -Details "task_id=$taskId title=$taskTitle handler=educonnect_health"

    $tasksUpdateUri = "$SBURL/rest/v1/az_tasks?id=eq.$taskId"

    $headers = $SBHeaders.Clone()
    $headers["Content-Type"] = "application/json"
    $headers["Prefer"]       = "return=minimal"

    # NOTE: we update last_run (NOT last_run_at)
    $bodyTask = @{
        status   = "doing"
        last_run = (Get-Date).ToString("o")
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $tasksUpdateUri -Headers $headers -Method Patch -Body $bodyTask | Out-Null

    & "F:\AION-ZERO\scripts\Enqueue-AZCommand.ps1" `
        -Command "educonnect_health" `
        -Project "EduConnect" `
        -TargetAgent "AION-ZERO"

    Write-AZTasksEvent -Action "command-enqueued" -Status "success" -Details "task_id=$taskId -> command=educonnect_health"
}
catch {
    $msg = $_.Exception.Message
    try {
        Write-AZTasksEvent -Action "tick-error" -Status "error" -Details $msg
    } catch { }
    throw
}
