param(
    # Path to the config JSON used by the ReflexEngine
    [string]$ConfigPath = "$PSScriptRoot\Jarvis-ReflexEngine.config.json",

    # Supabase base URL, e.g. https://abkprecmhitqmmlzxfad.supabase.co
    [string]$SupabaseUrl = $env:SUPABASE_URL,

    # Service role key (or a key with insert rights on the commands table)
    [string]$SupabaseServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY,

    # Name of the commands table - change if your table is not called az_commands
    [string]$CommandsTable = "az_commands"
)

$ErrorActionPreference = "Stop"

function Write-ReflexActionLog {
    param([string]$Message)
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "ReflexActions [$ts] $Message"
}

# --- Supabase sanity checks ---

if (-not $SupabaseUrl -or -not $SupabaseServiceKey) {
    Write-ReflexActionLog "ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set. Aborting."
    return
}

# --- 1) Refresh config from system telemetry ---

try {
    $configScript = Join-Path $PSScriptRoot "Jarvis-ReflexConfig-FromSystem.ps1"
    if (-not (Test-Path -LiteralPath $configScript)) {
        Write-ReflexActionLog "WARNING: Jarvis-ReflexConfig-FromSystem.ps1 not found. Skipping config refresh."
    }
    else {
        Write-ReflexActionLog "Running Jarvis-ReflexConfig-FromSystem.ps1..."
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $configScript -ConfigPath $ConfigPath
    }
}
catch {
    Write-ReflexActionLog ("ERROR running config script: {0}" -f $_.Exception.Message)
    return
}

# --- 2) Run ReflexEngine in JSON-only mode and capture its output ---

try {
    $engineScript = Join-Path $PSScriptRoot "Jarvis-ReflexEngine.ps1"
    if (-not (Test-Path -LiteralPath $engineScript)) {
        Write-ReflexActionLog "ERROR: Jarvis-ReflexEngine.ps1 not found."
        return
    }

    Write-ReflexActionLog "Running Jarvis-ReflexEngine.ps1 in JsonOnly mode..."
    $engineOutput = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $engineScript -ConfigPath $ConfigPath -JsonOnly

    if ($null -eq $engineOutput -or $engineOutput.Count -eq 0) {
        Write-ReflexActionLog "ReflexEngine returned empty output. Nothing to do."
        return
    }

    # Ensure we have a single JSON string
    if ($engineOutput -is [System.Array]) {
        $engineJson = ($engineOutput -join "`n").Trim()
    }
    else {
        $engineJson = ($engineOutput | Out-String).Trim()
    }

    if (-not $engineJson) {
        Write-ReflexActionLog "ReflexEngine JSON text is empty after trim. Nothing to do."
        return
    }

    Write-ReflexActionLog ("Raw JSON from ReflexEngine: {0}" -f $engineJson)

    $firedRules = $engineJson | ConvertFrom-Json
}
catch {
    Write-ReflexActionLog ("ERROR while running ReflexEngine or parsing JSON: {0}" -f $_.Exception.Message)
    return
}

if ($null -eq $firedRules) {
    Write-ReflexActionLog "No fired rules parsed. Exiting."
    return
}

if ($firedRules -isnot [System.Array]) {
    $firedRules = @($firedRules)
}

if ($firedRules.Count -eq 0) {
    Write-ReflexActionLog "No rules fired. Exiting."
    return
}

Write-ReflexActionLog ("Received {0} fired rule(s) from ReflexEngine." -f $firedRules.Count)

# --- 3) Insert commands into Supabase for each fired rule ---

$restEndpoint = "$SupabaseUrl/rest/v1/$CommandsTable"

$headers = @{
    "apikey"        = $SupabaseServiceKey
    "Authorization" = "Bearer $SupabaseServiceKey"
    "Content-Type"  = "application/json"
    "Prefer"        = "return=representation"
}

foreach ($rule in $firedRules) {

    $ruleId   = $rule.Id
    $ruleName = $rule.Name
    $trigger  = $rule.Trigger
    $reason   = $rule.Reason

    if (-not $ruleId)   { $ruleId   = -1 }
    if (-not $ruleName) { $ruleName = "Unnamed rule" }
    if (-not $trigger)  { $trigger  = "unknown" }
    if (-not $reason)   { $reason   = "No reason supplied" }

    # Payload aligned with your commands schema
    $bodyObject = @{
        project      = "AION-ZERO"
        target_agent = $null
        command      = "reflex.rule.fired"
        args         = @{
            rule_id   = $ruleId
            rule_name = $ruleName
            trigger   = $trigger
            reason    = $reason
        }
        status       = "queued"
        action       = "reflex"
        command_type = "reflex"
        priority     = 10
        payload_json = $null
    }

    $bodyJson = $bodyObject | ConvertTo-Json -Depth 6

    Write-ReflexActionLog ("Inserting command for rule {0} ({1})" -f $ruleId, $ruleName)
    Write-ReflexActionLog ("POST {0}" -f $restEndpoint)
    Write-ReflexActionLog ("Body: {0}" -f $bodyJson)

    try {
        $response = Invoke-WebRequest -Method Post -Uri $restEndpoint -Headers $headers -Body $bodyJson

        Write-ReflexActionLog ("HTTP status: {0}" -f $response.StatusCode)

        $respBody = $response.Content
        if ($respBody) {
            Write-ReflexActionLog ("Response body: {0}" -f $respBody)
        }
        else {
            Write-ReflexActionLog ("Empty response body from Supabase.")
        }
    }
    catch {
        Write-ReflexActionLog ("ERROR inserting command for rule {0}: {1}" -f $ruleId, $_.Exception.Message)
    }
}

Write-ReflexActionLog "Done inserting commands."
return
