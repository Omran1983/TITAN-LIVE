<#
.SYNOPSIS
    Basic health tests for CodeAgent wiring (az_commands for agent='code').

.DESCRIPTION
    - Checks az_commands is reachable.
    - Inserts a synthetic 'code' command for agent='code'.
    - Verifies the command is visible via REST (Commands feed equivalent).
    - Can be extended later to check E2E CodeAgent behaviour.

.NOTES
    Place in: F:\AION-ZERO\scripts\CodeAgent-RunTests.ps1

    Run from:
      PS> cd F:\AION-ZERO\scripts
      PS> .\CodeAgent-RunTests.ps1
#>

$ErrorActionPreference = 'Stop'

Write-Host "=== CodeAgent-RunTests.ps1 ==="

# 1) Load environment (same pattern as SecOps tests)
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

# 3) Test result aggregation
$global:CodeAgentTestResults = @()

function Add-TestResult {
    param(
        [string]$Name,
        [bool]$Success,
        [string]$Details = ""
    )
    $global:CodeAgentTestResults += [pscustomobject]@{
        Name    = $Name
        Success = $Success
        Details = $Details
    }
    if ($Success) {
        Write-Host "[PASS] $Name" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $Name - $Details" -ForegroundColor Red
    }
}

# 4) Structural test: az_commands reachable
function Test-CodeAgentCommandsTable {
    Write-Host "=== Test-CodeAgentCommandsTable ==="

    try {
        $res = Invoke-SupabaseRest -Path "/rest/v1/az_commands" -Method GET -Query @{ select = "id,project,action,agent,status"; limit = "1" }
        Add-TestResult -Name "az_commands accessible" -Success $true
    }
    catch {
        Add-TestResult -Name "az_commands accessible" -Success $false -Details $_.Exception.Message
    }
}

# 5) Behaviour test: synthetic CodeAgent command visible
function Test-CodeAgentCommandFeed {
    Write-Host "=== Test-CodeAgentCommandFeed ==="

    $nowIso  = (Get-Date).ToString("o")
    $marker  = "CodeAgent test command from CodeAgent-RunTests.ps1 at $nowIso"

    try {
        # Insert synthetic command for agent='code'
        $body = @(
            @{
                project = "codeagent_test"
                action  = "code"
                agent   = "code"
                status  = "queued"
                result  = $marker
            }
        )

        $insertRes = Invoke-SupabaseRest -Path "/rest/v1/az_commands" -Method POST -Body $body

        # Fetch last 10 commands for agent='code'
        $feed = Invoke-SupabaseRest -Path "/rest/v1/az_commands" -Method GET -Query @{
            select = "id,project,action,agent,status,result,created_at"
            agent  = "eq.code"
            order  = "id.desc"
            limit  = "10"
        }

        $found = $false
        foreach ($row in $feed) {
            if ([string]$row.result -like "*CodeAgent test command from CodeAgent-RunTests.ps1*") {
                $found = $true
                break
            }
        }

        Add-TestResult -Name "Commands feed shows 'code' agent commands" -Success $found -Details ("Found=" + $found)
    }
    catch {
        Add-TestResult -Name "Commands feed test" -Success $false -Details $_.Exception.Message
    }
}

# 6) Run tests
Write-Host "=== Running CodeAgent tests ==="
Test-CodeAgentCommandsTable
Test-CodeAgentCommandFeed

Write-Host ""
Write-Host "=== CodeAgent Test Summary ==="

$passed = $CodeAgentTestResults | Where-Object { $_.Success } | Measure-Object | Select-Object -ExpandProperty Count
$failed = $CodeAgentTestResults | Where-Object { -not $_.Success } | Measure-Object | Select-Object -ExpandProperty Count

$CodeAgentTestResults | Format-Table -AutoSize

Write-Host ""
Write-Host "Total tests: $($CodeAgentTestResults.Count)"
Write-Host "Passed     : $passed" -ForegroundColor Green

if ($failed -gt 0) {
    Write-Host "Failed     : $failed" -ForegroundColor Red
    exit 1
}
else {
    Write-Host "All CodeAgent tests passed." -ForegroundColor Green
    exit 0
}
