<#
    Jarvis-DumpCommand.ps1
    Fetches a single az_commands row by id and prints full JSON.
    Usage:
        cd F:\AION-ZERO\scripts
        powershell -NoProfile -ExecutionPolicy Bypass -File .\Jarvis-DumpCommand.ps1 -CommandId 131
#>

param(
    [Parameter(Mandatory = $true)]
    [int]$CommandId
)

Write-Host "=== Jarvis-DumpCommand ==="
Write-Host "CommandId = $CommandId"

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

$endpoint = "$($env:SUPABASE_URL)/rest/v1/az_commands?id=eq.$CommandId&select=*"
Write-Host "Endpoint = $endpoint"

$headers = @{
    apikey         = $env:SUPABASE_SERVICE_ROLE_KEY
    Authorization  = "Bearer $($env:SUPABASE_SERVICE_ROLE_KEY)"
    Accept         = "application/json"
}

try {
    $response = Invoke-RestMethod -Method Get -Uri $endpoint -Headers $headers
    Write-Host "Response JSON:"
    $response | ConvertTo-Json -Depth 8
    Write-Host "=== Jarvis-DumpCommand: DONE ==="
} catch {
    Write-Host "ERROR: Failed to fetch command."
    Write-Host $_.Exception.Message
    if ($_.ErrorDetails) {
        Write-Host $_.ErrorDetails
    }
    exit 1
}
