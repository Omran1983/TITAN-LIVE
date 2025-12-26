param(
    [Parameter(Mandatory = $true)]
    [string]$Project,          # e.g. 'AION-ZERO'

    [Parameter(Mandatory = $true)]
    [string]$Agent,            # e.g. 'jarvis_notify_worker'

    [Parameter(Mandatory = $true)]
    [string]$Action,           # e.g. 'notify'

    [Parameter(Mandatory = $true)]
    [string]$ArgsJson          # e.g. '{ "channel": "telegram", "message": "Hi" }'
)

Write-Host "=== Jarvis-PreflightEnqueue ===" -ForegroundColor Cyan

# Resolve script dir
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir  = Split-Path -Parent $scriptPath

# 1) Load env
$envLoader = Join-Path $scriptDir "Jarvis-LoadEnv.ps1"
if (-not (Test-Path $envLoader)) {
    Write-Host "ERROR: Jarvis-LoadEnv.ps1 not found at $envLoader" -ForegroundColor Red
    exit 1
}
. $envLoader
Write-Host "Loaded environment from Jarvis-LoadEnv.ps1." -ForegroundColor DarkGray

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY missing." -ForegroundColor Red
    exit 1
}

$baseUrl = $env:SUPABASE_URL.Trim().TrimEnd('/')

$headers = @{
    apikey        = $env:SUPABASE_SERVICE_ROLE_KEY
    Authorization = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    Accept        = "application/json"
    "Content-Type"= "application/json"
}

# 2) Parse args JSON
try {
    $argsObj = $ArgsJson | ConvertFrom-Json
} catch {
    Write-Host "ERROR: ArgsJson is not valid JSON: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3) Fetch contract for (agent, action)
$contractUrl = "$baseUrl/rest/v1/az_agent_contracts" +
               "?agent_key=eq.$Agent" +
               "&action=eq.$Action" +
               "&select=input_schema" +
               "&limit=1"

Write-Host "Contract URL: $contractUrl" -ForegroundColor DarkGray

try {
    $contractResp = Invoke-RestMethod -Method Get -Uri $contractUrl -Headers $headers -ErrorAction Stop
} catch {
    Write-Host "ERROR: Failed to fetch agent contract: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
        Write-Host "DETAILS: $($_.ErrorDetails.Message)" -ForegroundColor DarkRed
    }
    exit 1
}

if (-not $contractResp -or $contractResp.Count -eq 0) {
    Write-Host "ERROR: No contract found for agent='$Agent', action='$Action'." -ForegroundColor Red
    exit 1
}

$schema = $contractResp[0].input_schema
if (-not $schema) {
    Write-Host "ERROR: Contract has no input_schema for agent='$Agent', action='$Action'." -ForegroundColor Red
    exit 1
}

# 4) Simple validation: required fields exist
$requiredFields = @()
if ($schema.PSObject.Properties.Name -contains "required") {
    $requiredFields = @($schema.required)
}

if ($requiredFields.Count -gt 0) {
    Write-Host "Required fields: $($requiredFields -join ', ')" -ForegroundColor DarkGray
    foreach ($field in $requiredFields) {
        # Args object may be PSCustomObject; use PSObject properties to check
        $hasProp = $argsObj.PSObject.Properties.Name -contains $field
        if (-not $hasProp) {
            Write-Host "ERROR: Missing required field in args: '$field'." -ForegroundColor Red
            Write-Host "ArgsJson was: $ArgsJson" -ForegroundColor DarkYellow
            exit 1
        }
        $value = $argsObj.$field
        if ($null -eq $value -or ($value -is [string] -and [string]::IsNullOrWhiteSpace($value))) {
            Write-Host "ERROR: Required field '$field' is null or empty." -ForegroundColor Red
            Write-Host "ArgsJson was: $ArgsJson" -ForegroundColor DarkYellow
            exit 1
        }
    }
} else {
    Write-Host "No 'required' fields defined in schema; skipping required check." -ForegroundColor DarkGray
}

Write-Host "Preflight validation PASSED for agent='$Agent' action='$Action'." -ForegroundColor Green

# 5) Enqueue command in az_commands
$commandsUrl = "$baseUrl/rest/v1/az_commands"

# Convert args back to compact JSON for sending
$bodyObj = [ordered]@{
    project = $Project
    agent   = $Agent
    action  = $Action
    status  = "queued"
    args    = $argsObj
    logs    = "Queued via Jarvis-PreflightEnqueue"
}

$bodyJson = $bodyObj | ConvertTo-Json -Depth 10
Write-Host "POST $commandsUrl" -ForegroundColor DarkGray
Write-Host "Body: $bodyJson"   -ForegroundColor DarkGray

try {
    $resp = Invoke-RestMethod -Method Post -Uri $commandsUrl -Headers $headers -Body $bodyJson -ErrorAction Stop
    Write-Host "Command enqueued successfully." -ForegroundColor Green
    if ($resp) {
        Write-Host "Response:" -ForegroundColor DarkGray
        $resp | ConvertTo-Json -Depth 5 | Write-Host
    }
} catch {
    Write-Host "ERROR: Failed to enqueue command: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
        Write-Host "DETAILS: $($_.ErrorDetails.Message)" -ForegroundColor DarkRed
    }
    exit 1
}

Write-Host "=== Jarvis-PreflightEnqueue end ===" -ForegroundColor Cyan
