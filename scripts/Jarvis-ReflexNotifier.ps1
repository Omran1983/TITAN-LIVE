param(
    # Project to watch
    [string]$Project = "AION-ZERO",

    # Poll interval in seconds
    [int]$PollSeconds = 20,

    # Supabase settings
    [string]$SupabaseUrl = $env:SUPABASE_URL,
    [string]$SupabaseServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY,

    # Table name
    [string]$CommandsTable = "az_commands",

    # Local log + state
    [string]$LogFile   = "$PSScriptRoot\Jarvis-ReflexNotifier.log",
    [string]$StateFile = "$PSScriptRoot\Jarvis-ReflexNotifier.state.json"
)

$ErrorActionPreference = "Stop"

# ---------- Logging ----------

function Write-NotifierLog {
    param([string]$Message)

    $ts  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $msg = "ReflexNotifier [$ts] $Message"
    Write-Host $msg

    if ($LogFile -and $LogFile.Trim() -ne "") {
        try {
            Add-Content -LiteralPath $LogFile -Value $msg
        }
        catch {
            Write-Host "ReflexNotifier [$ts] Failed to write to log file: $($_.Exception.Message)"
        }
    }
}

# ---------- State (last processed id) ----------

function Load-NotifierState {
    if (-not (Test-Path -LiteralPath $StateFile)) {
        return @{
            lastCommandId = 0
        }
    }

    try {
        $json = Get-Content -LiteralPath $StateFile -Raw
        if (-not $json -or $json.Trim() -eq "") {
            return @{
                lastCommandId = 0
            }
        }
        $obj = $json | ConvertFrom-Json
        if ($null -eq $obj.lastCommandId) {
            return @{
                lastCommandId = 0
            }
        }
        return @{
            lastCommandId = [int]$obj.lastCommandId
        }
    }
    catch {
        Write-NotifierLog ("ERROR loading state: {0}" -f $_.Exception.Message)
        return @{
            lastCommandId = 0
        }
    }
}

function Save-NotifierState {
    param([int]$LastCommandId)

    $obj = [pscustomobject]@{
        lastCommandId = $LastCommandId
    }

    try {
        $json = $obj | ConvertTo-Json -Depth 4
        Set-Content -LiteralPath $StateFile -Value $json -Encoding UTF8
    }
    catch {
        Write-NotifierLog ("ERROR saving state: {0}" -f $_.Exception.Message)
    }
}

# ---------- Supabase setup ----------

if (-not $SupabaseUrl -or -not $SupabaseServiceKey) {
    Write-NotifierLog "ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set. Aborting."
    return
}

$CommandsEndpoint = "$SupabaseUrl/rest/v1/$CommandsTable"

$CommonHeaders = @{
    "apikey"        = $SupabaseServiceKey
    "Authorization" = "Bearer $SupabaseServiceKey"
    "Content-Type"  = "application/json"
    "Prefer"        = "return=representation"
}

Write-NotifierLog ("CommandsEndpoint = {0}" -f $CommandsEndpoint)

# ---------- Fetch new reflex events ----------

function Get-NewReflexEvents {
    param(
        [string]$Project,
        [int]$LastId
    )

    # Only fetch reflex actions that are done and have id > LastId
    $query =
        "?select=*&" +
        "project=eq.$([Uri]::EscapeDataString($Project))&" +
        "action=eq.reflex&" +
        "status=eq.done&" +
        ("id=gt.{0}&" -f $LastId) +
        "order=id.asc&" +
        "limit=100"

    $url = "$script:CommandsEndpoint$query"

    Write-NotifierLog ("Checking for new reflex events (id > {0}): {1}" -f $LastId, $url)

    try {
        $resp = Invoke-RestMethod -Method Get -Uri $url -Headers $script:CommonHeaders
    }
    catch {
        Write-NotifierLog ("ERROR GET reflex events: {0}" -f $_.Exception.Message)
        return @()
    }

    if ($null -eq $resp) {
        return @()
    }

    if ($resp -isnot [System.Array]) {
        $resp = @($resp)
    }

    return $resp
}

# ---------- Insert notify command in az_commands ----------

function Insert-NotifyCommand {
    param(
        $SourceCommand,
        [string]$AlertMessage,
        $AlertPayload
    )

    $srcId  = $SourceCommand.id
    $args   = $SourceCommand.args
    $ruleId = $null
    $ruleName = $null
    $trigger = $null
    $reason  = $null

    if ($args) {
        $ruleId   = $args.rule_id
        $ruleName = $args.rule_name
        $trigger  = $args.trigger
        $reason   = $args.reason
    }

    $bodyObject = @{
        project       = $Project
        action        = "notify"
        command_type  = "notify"
        command       = "notify.alert"
        status        = "queued"
        target_agent  = $null
        priority      = 20
        payload_json  = $null
        args          = @{
            source_action      = "reflex"
            source_command_id  = $srcId
            rule_id            = $ruleId
            rule_name          = $ruleName
            trigger            = $trigger
            reason             = $reason
            alert_message      = $AlertMessage
            alert_payload      = $AlertPayload
        }
    }

    $bodyJson = $bodyObject | ConvertTo-Json -Depth 10

    Write-NotifierLog ("Inserting notify.alert command for reflex id={0}" -f $srcId)
    Write-NotifierLog ("POST {0}" -f $script:CommandsEndpoint)
    Write-NotifierLog ("Body: {0}" -f $bodyJson)

    try {
        $resp = Invoke-RestMethod -Method Post -Uri $script:CommandsEndpoint -Headers $script:CommonHeaders -Body $bodyJson
        Write-NotifierLog ("Notify command inserted for reflex id={0}. Response: {1}" -f $srcId, ($resp | ConvertTo-Json -Depth 4))
    }
    catch {
        Write-NotifierLog ("ERROR inserting notify command for reflex id={0}: {1}" -f $srcId, $_.Exception.Message)
    }
}

# ---------- Build alert message from command ----------

function Build-AlertFromCommand {
    param(
        $Command
    )

    $args        = $Command.args
    $resultJson  = $Command.result_json
    $project     = $Command.project
    $id          = $Command.id

    $ruleId      = $null
    $ruleName    = $null
    $trigger     = $null
    $reason      = $null

    if ($args) {
        $ruleId   = $args.rule_id
        $ruleName = $args.rule_name
        $trigger  = $args.trigger
        $reason   = $args.reason
    }

    $payloadObj = $null
    if ($resultJson) {
        try {
            $payloadObj = $resultJson | ConvertFrom-Json
        }
        catch {
            Write-NotifierLog ("WARN: Failed to parse result_json for id={0}: {1}" -f $id, $_.Exception.Message)
        }
    }

    $alertMessage = $null
    if ($payloadObj -and $payloadObj.alert_message) {
        $alertMessage = [string]$payloadObj.alert_message
    }
    else {
        # Fallback message if result_json is missing/wrong
        $alertMessage = "Reflex alert (command id=$id, project=$project, rule=$ruleName, trigger=$trigger): $reason"
    }

    return @{
        Message = $alertMessage
        Payload = $payloadObj
    }
}

# ---------- Main loop ----------

Write-NotifierLog ("Starting Reflex Notifier for project '{0}'." -f $Project)

$state = Load-NotifierState
$lastId = [int]$state.lastCommandId
Write-NotifierLog ("Loaded state: lastCommandId = {0}" -f $lastId)

while ($true) {
    try {
        $events = Get-NewReflexEvents -Project $Project -LastId $lastId

        if ($events.Count -eq 0) {
            Write-NotifierLog "No new reflex events. Sleeping..."
            Start-Sleep -Seconds $PollSeconds
            continue
        }

        Write-NotifierLog ("Found {0} new reflex event(s)." -f $events.Count)

        foreach ($cmd in $events) {
            $id = $cmd.id
            Write-NotifierLog ("Processing reflex command id={0}" -f $id)

            $alertInfo = Build-AlertFromCommand -Command $cmd
            $alertMessage = $alertInfo.Message
            $alertPayload = $alertInfo.Payload

            # 1) Write to local alerts log
            Write-NotifierLog ("ALERT: {0}" -f $alertMessage)

            # 2) Insert notify.alert command on the bus
            Insert-NotifyCommand -SourceCommand $cmd -AlertMessage $alertMessage -AlertPayload $alertPayload

            if ($id -gt $lastId) {
                $lastId = $id
            }
        }

        Save-NotifierState -LastCommandId $lastId
        Write-NotifierLog ("State saved. lastCommandId = {0}" -f $lastId)

        # Short pause before next cycle
        Start-Sleep -Seconds $PollSeconds
    }
    catch {
        Write-NotifierLog ("Top-level notifier loop error: {0}" -f $_.Exception.Message)
        Start-Sleep -Seconds $PollSeconds
    }
}
