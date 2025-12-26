# F:\AION-ZERO\scripts\AZ-Guard.ps1

$ErrorActionPreference = "Stop"

$targets = @(
    "Jarvis-Watcher",
    "AZ-Infra-Ping",
    "AZ-Health",
    "Proxy-Watcher"
)

. "F:\AION-ZERO\scripts\Load-Supabase.ps1"

$now    = Get-Date
$issues = @()

foreach ($name in $targets) {
    try {
        $task = Get-ScheduledTask -TaskName $name -ErrorAction Stop
        $info = Get-ScheduledTaskInfo -TaskName $name -ErrorAction Stop

        $state      = $task.State.ToString()
        $lastResult = $info.LastTaskResult
        $lastRun    = $info.LastRunTime
        $nextRun    = $info.NextRunTime

        $ageMinutes = $null
        if ($lastRun -gt [datetime]::MinValue) {
            $ageMinutes = ($now - $lastRun).TotalMinutes
        }

        $ok = $true
        $details = "State=$state; LastResult=$lastResult; LastRun=$lastRun; NextRun=$nextRun"

        if ($lastResult -ne 0) {
            $ok = $false
            $details = "ERROR result; " + $details
        }
        elseif ($state -eq "Disabled") {
            $ok = $false
            $details = "Disabled; " + $details
        }
        elseif ($ageMinutes -ne $null -and $ageMinutes -gt 30) {
            $ok = $false
            $details = "Stale (>30m); " + $details
        }

        if ($ok) {
            & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
                -Project "System" `
                -Agent "AZ-Guard" `
                -Action "task-ok" `
                -Status "success" `
                -Details ("{0} ok; {1}" -f $name, $details)
        }
        else {
            $issues += "$name issue"
            & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
                -Project "System" `
                -Agent "AZ-Guard" `
                -Action "task-issue" `
                -Status "error" `
                -Details ("{0} issue; {1}" -f $name, $details)

            schtasks /Run /TN $name | Out-Null

            & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
                -Project "System" `
                -Agent "AZ-Guard" `
                -Action "task-restart" `
                -Status "warning" `
                -Details ("{0} restarted by AZ-Guard" -f $name)
        }
    }
    catch {
        $issues += "$name missing"
        & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
            -Project "System" `
            -Agent "AZ-Guard" `
            -Action "task-missing" `
            -Status "error" `
            -Details ("{0} missing: {1}" -f $name, $_.Exception.Message)
    }
}

if ($issues.Count -eq 0) {
    & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
        -Project "System" `
        -Agent "AZ-Guard" `
        -Action "cycle-ok" `
        -Status "success" `
        -Details "All tasks healthy"
}
else {
    & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
        -Project "System" `
        -Agent "AZ-Guard" `
        -Action "cycle-issue" `
        -Status "warning" `
        -Details ("Issues: {0}" -f ($issues -join "; "))
}
