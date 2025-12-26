# F:\AION-ZERO\scripts\Jarvis-Tick.ps1

$ErrorActionPreference = "Stop"

$global:JarvisAgent = "Jarvis"

function Write-JarvisEvent {
    param(
        [string]$Action,
        [string]$Status  = "success",
        [string]$Details = $null
    )

    & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
        -Project "System" `
        -Agent   $global:JarvisAgent `
        -Action  $Action `
        -Status  $Status `
        -Details $Details
}

try {
    . "F:\AION-ZERO\scripts\Load-Supabase.ps1"

    Write-JarvisEvent -Action "tick-start" -Status "running" -Details "Reviewing az_tasks for auto-updates"

    $tasksUri = "$SBURL/rest/v1/az_tasks" +
                "?select=id,project_id,title,status,kind,owner,priority,last_run,created_at" +
                "&status=in.(doing,pending)" +
                "&order=priority.asc,created_at.asc" +
                "&limit=20"

    $tasks = Invoke-RestMethod -Uri $tasksUri -Headers $SBHeaders -Method Get

    if (-not $tasks) {
        Write-JarvisEvent -Action "no-tasks" -Status "success" -Details "No doing/pending tasks"
        return
    }

    if ($tasks -isnot [array]) {
        $tasks = @($tasks)
    }

    $targetTask = $tasks | Where-Object {
        $_.status -eq "doing" -and
        $_.title -like "EduConnect: Cloudflare Worker health*"
    } | Select-Object -First 1

    if (-not $targetTask) {
        Write-JarvisEvent -Action "no-dispatchable-task" -Status "success" -Details "No EduConnect health task in doing state"
        return
    }

    $taskId = $targetTask.id

    # --- Load last EduConnect-Health event ---
    $eventsUri = "$SBURL/rest/v1/proxy_events" +
                 "?select=project,agent,action,status,details,created_at" +
                 "&project=eq.EduConnect" +
                 "&agent=eq.EduConnect-Health" +
                 "&action=eq.worker-health" +
                 "&order=created_at.desc" +
                 "&limit=1"

    $lastHealth = Invoke-RestMethod -Uri $eventsUri -Headers $SBHeaders -Method Get

    if (-not $lastHealth) {
        Write-JarvisEvent -Action "no-health-event" -Status "success" -Details "No EduConnect-Health events yet"
        return
    }

    if ($lastHealth -is [array]) {
        $lastHealth = $lastHealth[0]
    }

    # --- Safe DateTime parse for created_at ---
    $rawCreatedAt = [string]$lastHealth.created_at
    $healthTime   = $null

    $culture = [System.Globalization.CultureInfo]::InvariantCulture
    $styles  = [System.Globalization.DateTimeStyles]::AssumeUniversal

    $formats = @(
        'yyyy-MM-ddTHH:mm:ssK',
        'yyyy-MM-ddTHH:mm:ss.fffffffK',
        'MM/dd/yyyy HH:mm:ss',
        'dd/MM/yyyy HH:mm:ss'
    )

    $parsed = $false

    foreach ($fmt in $formats) {
        try {
            $healthTime = [DateTime]::ParseExact($rawCreatedAt, $fmt, $culture, $styles)
            $parsed = $true
            break
        } catch { }
    }

    if (-not $parsed) {
        try {
            $healthTime = [DateTime]::Parse($rawCreatedAt, $culture, $styles)
            $parsed = $true
        } catch { }
    }

    if (-not $parsed -or -not $healthTime) {
        throw "Could not parse created_at '$rawCreatedAt' as DateTime"
    }

    $healthOk = ($lastHealth.status -eq "success")

    # Simple rule: if health was success in the last 15 minutes, mark task as done
    $now          = Get-Date
    $recentEnough = ($now - $healthTime).TotalMinutes -le 15

    if (-not $healthOk -or -not $recentEnough) {
        $reason = "last health status=$($lastHealth.status) at $healthTime (recent=$recentEnough)"
        Write-JarvisEvent -Action "health-not-ok-yet" -Status "success" -Details $reason
        return
    }

    # --- Mark task as done ---
    $tasksUpdateUri = "$SBURL/rest/v1/az_tasks?id=eq.$taskId"

    $headers = $SBHeaders.Clone()
    $headers["Content-Type"] = "application/json"
    $headers["Prefer"]       = "return=minimal"

    $bodyTask = @{
        status    = "done"
        last_run  = $healthTime.ToString("o")
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $tasksUpdateUri -Headers $headers -Method Patch -Body $bodyTask | Out-Null

    Write-JarvisEvent -Action "task-closed" -Status "success" -Details "task_id=$taskId title=$($targetTask.title) -> done"
}
catch {
    $msg = $_.Exception.Message
    try {
        Write-JarvisEvent -Action "tick-error" -Status "error" -Details $msg
    } catch { }
    throw
}
