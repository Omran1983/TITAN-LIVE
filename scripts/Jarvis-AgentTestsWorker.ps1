$ErrorActionPreference = 'Stop'

Write-Host "=== Jarvis-AgentTestsWorker ==="

# 1) Resolve paths
if ($MyInvocation.MyCommand.Path) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $scriptDir = Get-Location
}
$rootDir  = Split-Path -Parent $scriptDir

$loadEnv  = Join-Path $scriptDir 'Jarvis-LoadEnv.ps1'
$testScript = Join-Path $scriptDir 'RunAllAgentTests.ps1'

if (Test-Path $loadEnv) {
    Write-Host "Loading environment from $loadEnv ..."
    . $loadEnv
} else {
    Write-Warning "Jarvis-LoadEnv.ps1 not found. Ensure env vars are set manually."
}

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    throw "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set. Aborting."
}

if (-not (Test-Path $testScript)) {
    throw "RunAllAgentTests.ps1 not found at $testScript. Aborting."
}

$baseUrl = $env:SUPABASE_URL.TrimEnd('/')
$apiKey  = $env:SUPABASE_SERVICE_ROLE_KEY

function Invoke-SupabaseRest {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [string]$Method = 'GET',
        [object]$Body = $null,
        [hashtable]$Query = @{}
    )

    $uriBuilder = [System.UriBuilder]("$baseUrl$Path")
    if ($Query.Count -gt 0) {
        $qs = $Query.GetEnumerator() | ForEach-Object {
            [System.Uri]::EscapeDataString($_.Key) + "=" + [System.Uri]::EscapeDataString([string]$_.Value)
        }
        $uriBuilder.Query = ($qs -join "&")
    }

    $headers = @{
        apikey        = $apiKey
        Authorization = "Bearer $apiKey"
        Accept        = "application/json"
        Prefer        = "return=representation"
    }

    $params = @{
        Uri     = $uriBuilder.Uri.AbsoluteUri
        Method  = $Method
        Headers = $headers
    }

    if ($Body -ne $null) {
        $params.ContentType = "application/json"
        $params.Body        = ($Body | ConvertTo-Json -Depth 10)
    }

    return Invoke-RestMethod @params
}

function Get-PendingAgentTestCommands {
    # Commands that request running the full agent test suite
    $query = @{
        select = "*"
        project = "eq.aion_zero"
        action  = "eq.run_agent_tests"
        status  = "eq.queued"
        order   = "id.asc"
        limit   = "10"
    }

    return Invoke-SupabaseRest -Path "/rest/v1/az_commands" -Method GET -Query $query
}

function Update-CommandStatus {
    param(
        [int]$Id,
        [string]$Status,
        [string]$ResultText
    )

    $body = @{
        status = $Status
        result = $ResultText
        finished_at = (Get-Date).ToString("o")
    }

    $query = @{ id = "eq.$Id" }

    Invoke-SupabaseRest -Path "/rest/v1/az_commands" -Method PATCH -Body $body -Query $query | Out-Null
}

Write-Host "Fetching queued 'run_agent_tests' commands ..."

$commands = Get-PendingAgentTestCommands

if (-not $commands -or $commands.Count -eq 0) {
    Write-Host "No queued agent test commands found. Exiting."
    exit 0
}

foreach ($cmd in $commands) {
    $id = $cmd.id
    Write-Host "Processing command id=$id (run_agent_tests) ..."

    # Mark as in_progress
    Update-CommandStatus -Id $id -Status "in_progress" -ResultText "Agent tests starting on worker."

    # Run the aggregated test script
    & $testScript
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        Write-Host "RunAllAgentTests.ps1 completed successfully for command id=$id"
        Update-CommandStatus -Id $id -Status "done" -ResultText "Agent tests passed (exit code 0)."
    } else {
        Write-Warning "RunAllAgentTests.ps1 failed (exit code $exitCode) for command id=$id"
        Update-CommandStatus -Id $id -Status "error" -ResultText "Agent tests failed (exit code $exitCode)."
    }
}

Write-Host "=== Jarvis-AgentTestsWorker finished ==="
exit 0
