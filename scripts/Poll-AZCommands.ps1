# F:\AION-ZERO\scripts\Poll-AZCommands.ps1
$ErrorActionPreference = "Stop"

. "F:\AION-ZERO\scripts\Load-Supabase.ps1"

$baseUri = "$SBURL/rest/v1/az_commands"

$headersJson = $SBHeaders.Clone()
$headersJson["Content-Type"] = "application/json"
$headersJson["Prefer"]       = "return=representation"

function Set-CommandStatus {
    param(
        [int]$Id,
        [string]$Status,
        [string]$ErrorMessage = $null
    )

    $body = @{
        status       = $Status
        completed_at = (Get-Date).ToString("o")
    }

    if ($Status -eq "processing") {
        $body.Remove("completed_at") | Out-Null
        $body["picked_at"] = (Get-Date).ToString("o")
    }

    if ($ErrorMessage) {
        $body["error"] = $ErrorMessage
    }

    $json = $body | ConvertTo-Json -Depth 5
    $uri  = "$baseUri?id=eq.$Id"

    Invoke-RestMethod -Uri $uri -Headers $headersJson -Method Patch -Body $json | Out-Null
}

# 1) Fetch pending commands
$uri = "$baseUri?select=id,project,target_agent,command,args,status,created_at" +
       "&status=eq.pending" +
       "&order=created_at.asc" +
       "&limit=10"

try {
    $cmds = Invoke-RestMethod -Uri $uri -Headers $SBHeaders -Method Get
} catch {
    & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
        -Project "System" `
        -Agent "AZ-Command" `
        -Action "fetch-error" `
        -Status "error" `
        -Details $_.Exception.Message
    exit 1
}

if (-not $cmds -or $cmds.Count -eq 0) {
    & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
        -Project "System" `
        -Agent "AZ-Command" `
        -Action "idle" `
        -Status "success" `
        -Details "No pending az_commands"
    exit 0
}

foreach ($c in $cmds) {
    $id      = [int]$c.id
    $cmdName = $c.command
    $proj    = $c.project
    $tAgent  = $c.target_agent
    $args    = $c.args

    try {
        Set-CommandStatus -Id $id -Status "processing"

        $note = $null

        switch ($cmdName) {
            "start_az" {
                schtasks /Run /TN "Start-AZ" | Out-Null
                $note = "Start-AZ task triggered"
            }
            "restart_guard" {
                schtasks /Run /TN "AZ-Guard" | Out-Null
                $note = "AZ-Guard restart triggered"
            }
            "health_check" {
                schtasks /Run /TN "AZ-Health" | Out-Null
                $note = "AZ-Health task triggered"
            }
            "proxy_check" {
                schtasks /Run /TN "Proxy-Watcher" | Out-Null
                $note = "Proxy-Watcher task triggered"
            }
            "jarvis_tick" {
                schtasks /Run /TN "Jarvis-Watcher" | Out-Null
                $note = "Jarvis-Watcher tick triggered"
            }
            default {
                $note = "Unknown command: $cmdName"
            }
        }

        if ($note -like "Unknown*") {
            Set-CommandStatus -Id $id -Status "error" -ErrorMessage $note

            & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
                -Project $proj `
                -Agent "AZ-Command" `
                -Action "execute" `
                -Status "error" `
                -Details ("{0} (id={1}) - {2}" -f $cmdName, $id, $note)
        }
        else {
            Set-CommandStatus -Id $id -Status "done"

            & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
                -Project $proj `
                -Agent "AZ-Command" `
                -Action "execute" `
                -Status "success" `
                -Details ("{0} (id={1}) - {2}" -f $cmdName, $id, $note)
        }
    }
    catch {
        $err = $_.Exception.Message
        Set-CommandStatus -Id $id -Status "error" -ErrorMessage $err

        & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
            -Project $proj `
            -Agent "AZ-Command" `
            -Action "execute" `
            -Status "error" `
            -Details ("{0} (id={1}) failed: {2}" -f $cmdName, $id, $err)
    }
}
