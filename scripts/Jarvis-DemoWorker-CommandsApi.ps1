<#
    Jarvis-DemoWorker-CommandsApi.ps1
    ---------------------------------
    Simple demo worker that:
      - Loads environment (SUPABASE_URL, COMMANDS_API_URL, etc. via Jarvis-LoadEnv.ps1)
      - Pings CommandsApi /health
      - Sends a test command to /commands that matches az_commands-style schema.

    Expected POST /commands body (superset):

      {
        "project": "AION-ZERO",
        "agent": "DemoWorker",
        "source": "DemoWorker",
        "action": "code",
        "status": "queued",
        "instruction": "Demo command from DemoWorker",
        "args": { ... },
        "payload": { ... }   // duplicate of args for safety
      }
#>

param(
    [string]$Project   = "AION-ZERO",
    [string]$Source    = "DemoWorker",
    [string]$BaseUrl   = ""
)

$ErrorActionPreference = "Stop"

Write-Host "=== Jarvis-DemoWorker-CommandsApi ==="

# Resolve script dir and load env
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "ScriptDir: $scriptDir"

. "$scriptDir\Jarvis-LoadEnv.ps1"
Write-Host "Loaded environment variables from F:\AION-ZERO\.env"

# Read CommandsApi base URL from env if not passed
if (-not $BaseUrl -or $BaseUrl.Trim() -eq "") {
    $BaseUrl = $env:COMMANDS_API_URL
}

if (-not $BaseUrl -or $BaseUrl.Trim() -eq "") {
    # Hard default
    $BaseUrl = "http://127.0.0.1:5051"
}

Write-Host "CommandsApi base URL: $BaseUrl"

# 1) Health check
$healthUrl = "$BaseUrl/health"
Write-Host "CommandsApi health URL: $healthUrl"

try {
    $health = Invoke-RestMethod -Method Get -Uri $healthUrl -TimeoutSec 5
    Write-Host ("CommandsApi health: status={0} project={1} time={2}" -f $health.status, $health.project, $health.time)
}
catch {
    $ex = $_.Exception
    Write-Warning ("CommandsApi health check failed: {0}" -f $ex.Message)
    # Continue anyway so we see what happens on POST
}

# 2) Build demo command payload matching az_commands shape
$nowIso = (Get-Date).ToString("s")

$commonArgs = @{
    message  = "Hello from $Source at $nowIso"
    context  = "Testing /commands integration from PowerShell demo worker."
    metadata = @{
        env       = "local"
        machine   = $env:COMPUTERNAME
        username  = $env:USERNAME
        timestamp = $nowIso
    }
}

$commandBodyHashtable = @{
    project     = $Project
    agent       = $Source      # who is responsible
    source      = $Source      # which worker produced this
    action      = "code"       # aligns with CodeAgent query action=eq.code
    status      = "queued"     # initial status
    instruction = "Demo command from DemoWorker (echo message/context)."
    args        = $commonArgs  # what CodeAgent will see
    payload     = $commonArgs  # extra copy in case API expects 'payload'
}

$commandBodyJson = $commandBodyHashtable | ConvertTo-Json -Depth 10

Write-Host "POST /commands request body:"
Write-Host $commandBodyJson

# 3) Send POST /commands
$commandsUrl = "$BaseUrl/commands"
Write-Host "Sending command to: $commandsUrl"

try {
    $response = Invoke-RestMethod -Method Post `
        -Uri $commandsUrl `
        -ContentType "application/json" `
        -Body $commandBodyJson

    Write-Host "Response from /commands:"
    $response | ConvertTo-Json -Depth 10
}
catch {
    $ex = $_.Exception
    Write-Error ("Send-JarvisCommand failed (POST {0}): {1}" -f $commandsUrl, $ex.Message)
}
