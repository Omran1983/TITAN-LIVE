<#
.SYNOPSIS
    Run all registered agent test harnesses and emit a single health summary.

.DESCRIPTION
    - Runs SecOps-RunTests.ps1 and CodeAgent-RunTests.ps1.
    - Aggregates pass/fail across agents.
    - Queues a single 'notify' command into az_commands with the summary.
    - Exits 0 if all passed, 1 if any failed.

.NOTES
    Place in: F:\AION-ZERO\scripts\RunAllAgentTests.ps1

    Usage:
      PS> cd F:\AION-ZERO\scripts
      PS> .\RunAllAgentTests.ps1
#>

$ErrorActionPreference = 'Stop'

Write-Host "=== RunAllAgentTests.ps1 ==="

# 1) Load environment (Jarvis-LoadEnv.ps1) to get SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY
if ($MyInvocation.MyCommand.Path) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $scriptDir = Get-Location
}
$rootDir = Split-Path -Parent $scriptDir

$loadEnv = Join-Path $scriptDir 'Jarvis-LoadEnv.ps1'
if (Test-Path $loadEnv) {
    Write-Host "Loading environment from $loadEnv ..."
    . $loadEnv
} else {
    Write-Warning "Jarvis-LoadEnv.ps1 not found. Ensure env vars are set manually."
}

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    throw "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set. Aborting tests."
}

$baseUrl = $env:SUPABASE_URL.TrimEnd('/')
$apiKey  = $env:SUPABASE_SERVICE_ROLE_KEY

# 2) Supabase REST helper
function Invoke-SupabaseRest {
    param(
        [Parameter(Mandatory=$true)][string]$Path,   # e.g. /rest/v1/az_commands
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

    $response = Invoke-RestMethod @params
    return $response
}

# 3) Helper: send one aggregated alert into az_commands
function Send-AgentTestAlert {
    param(
        [string]$Status,   # "ok" or "failed"
        [string]$Summary
    )

    try {
        $body = @(
            @{
                project = "agent_tests"
                action  = "notify"
                agent   = "notify"
                status  = "queued"
                result  = "Agent tests status: $Status. $Summary"
            }
        )

        Invoke-SupabaseRest -Path "/rest/v1/az_commands" -Method POST -Body $body | Out-Null
        Write-Host "Queued agent test alert: $Status"
    }
    catch {
        Write-Warning "Failed to queue AgentTest alert: $($_.Exception.Message)"
    }
}

# 4) Test registry
$tests = @(
    @{
        Name = "SecOps"
        Path = "F:\AION-ZERO\scripts\SecOps-RunTests.ps1"
    },
    @{
        Name = "CodeAgent"
        Path = "F:\AION-ZERO\scripts\CodeAgent-RunTests.ps1"
    }
)

$results = @()

# 5) Run tests sequentially, capture exit codes
foreach ($t in $tests) {
    $name = $t.Name
    $path = $t.Path

    if (-not (Test-Path $path)) {
        Write-Host "[SKIP] $name tests (script not found at $path)" -ForegroundColor Yellow
        $results += [pscustomobject]@{
            Agent     = $name
            Script    = $path
            Success   = $false
            ExitCode  = 127
            Skipped   = $true
            Message   = "Script not found"
        }
        continue
    }

    Write-Host "=== Running tests for $name ==="
    & $path
    $exitCode = $LASTEXITCODE

    $success = ($exitCode -eq 0)
    if ($success) {
        Write-Host "[PASS] $name tests (exit code 0)" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $name tests (exit code $exitCode)" -ForegroundColor Red
    }

    $results += [pscustomobject]@{
        Agent     = $name
        Script    = $path
        Success   = $success
        ExitCode  = $exitCode
        Skipped   = $false
        Message   = ""
    }
}

Write-Host ""
Write-Host "=== All Agent Tests Summary ==="
$results | Format-Table -AutoSize

$total   = $results.Count
$passed  = ($results | Where-Object { $_.Success }).Count
$failed  = ($results | Where-Object { -not $_.Success -and -not $_.Skipped }).Count
$skipped = ($results | Where-Object { $_.Skipped }).Count

Write-Host ""
Write-Host "Total agents: $total"
Write-Host "Passed      : $passed"  -ForegroundColor Green
Write-Host "Failed      : $failed"  -ForegroundColor Red
Write-Host "Skipped     : $skipped" -ForegroundColor Yellow

$summaryParts = @()
$summaryParts += "Total=$total"
$summaryParts += "Passed=$passed"
$summaryParts += "Failed=$failed"
$summaryParts += "Skipped=$skipped"

$summary = ($summaryParts -join ", ")

if ($failed -gt 0) {
    Send-AgentTestAlert -Status "failed" -Summary $summary
    Write-Host "Agent tests FAILED." -ForegroundColor Red
    exit 1
} else {
    Send-AgentTestAlert -Status "ok" -Summary $summary
    Write-Host "All agent tests passed." -ForegroundColor Green
    exit 0
}
