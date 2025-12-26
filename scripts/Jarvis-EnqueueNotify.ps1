<#
    Jarvis-EnqueueNotify.ps1
    Enqueue a notify command into az_commands.

    Usage:
        cd F:\AION-ZERO\scripts
        powershell -NoProfile -ExecutionPolicy Bypass -File .\Jarvis-EnqueueNotify.ps1 -Message "Something happened"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Message,

    [string]$Project = "AION-ZERO",

    [int]$Priority = 100
)

Write-Host "=== Jarvis-EnqueueNotify ==="
Write-Host "Project = $Project"
Write-Host "Message = $Message"

# Resolve script directory and load env
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

$loadEnvPath = Join-Path $scriptDir "Jarvis-LoadEnv.ps1"
if (Test-Path $loadEnvPath) {
    Write-Host "Loading environment from .env via Jarvis-LoadEnv.ps1 ..."
    & $loadEnvPath
} else {
    Write-Host "WARNING: Jarvis-LoadEnv.ps1 not found. Assuming env vars already set."
}

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is not set in the environment."
    exit 1
}

$commandsEndpoint = "$($env:SUPABASE_URL)/rest/v1/az_commands"
Write-Host "CommandsEndpoint = $commandsEndpoint"

$headers = @{
    apikey         = $env:SUPABASE_SERVICE_ROLE_KEY
    Authorization  = "Bearer $($env:SUPABASE_SERVICE_ROLE_KEY)"
    Accept         = "application/json"
    "Content-Type" = "application/json"
    Prefer         = "return=representation"
}

$nowUtc = (Get-Date).ToUniversalTime().ToString("o")

$bodyObject = @{
    project       = $Project
    agent         = "jarvis_notify_worker"
    action        = "notify"
    status        = "queued"
    command       = $Message
    args          = @{}
    priority      = $Priority
    scheduled_at  = $null
    command_type  = $null
    payload_json  = $null
    payload       = $null
}

$bodyJson = $bodyObject | ConvertTo-Json -Depth 5
Write-Host "Posting notify command ..."
Write-Host $bodyJson

try {
    $response = Invoke-RestMethod -Method Post -Uri $commandsEndpoint -Headers $headers -Body $bodyJson
    Write-Host "Insert response:"
    $response | ConvertTo-Json -Depth 5
    Write-Host "=== Jarvis-EnqueueNotify: DONE ==="
} catch {
    Write-Host "ERROR: Failed to enqueue notify command."
    Write-Host $_.Exception.Message
    if ($_.ErrorDetails) {
        Write-Host $_.ErrorDetails
    }
    exit 1
}
