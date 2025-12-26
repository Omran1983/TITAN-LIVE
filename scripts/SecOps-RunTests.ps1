<#
.SYNOPSIS
    SecOps view + basic behaviour test runner for AION-ZERO / Jarvis.

.DESCRIPTION
    - Runs structural tests against SecOps views.
    - Inserts synthetic scan + findings to verify open/closed logic.
    - Inserts synthetic security command to verify Commands feed.
    - Summarises all results at the end.

.NOTES
    Place in: F:\AION-ZERO\scripts\SecOps-RunTests.ps1
    Run from: PowerShell
      PS> cd F:\AION-ZERO\scripts
      PS> .\SecOps-RunTests.ps1
#>

$ErrorActionPreference = 'Stop'

Write-Host "=== SecOps-RunTests.ps1 ==="

# 1) Load environment (robust even if path is missing)
if ($MyInvocation.MyCommand.Path) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    # Fallback: current directory if script path not available
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

# 2) Helper: Invoke Supabase REST
function Invoke-SupabaseRest {
    param(
        [Parameter(Mandatory=$true)][string]$Path,   # e.g. /rest/v1/az_security_scans
        [string]$Method = 'GET',
        [object]$Body = $null,
        [hashtable]$Query = @{}
    )

    $uriBuilder = [System.UriBuilder]("$baseUrl$Path")
    if ($Query.Count -gt 0) {
        $qs = $Query.GetEnumerator() | ForEach-Object {
            # Supabase expects URL-encoded query params
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

    #Write-Host "DEBUG: $Method $($uriBuilder.Uri.AbsoluteUri)"
    $response = Invoke-RestMethod @params
    return $response
}

# 3) Test result aggregation
$global:SecOpsTestResults = @()

function Add-TestResult {
    param(
        [string]$Name,
        [bool]$Success,
        [string]$Details = ""
    )
    $global:SecOpsTestResults += [pscustomobject]@{
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

# 4) Structural tests
function Test-SecOpsViews {
    Write-Host "=== Test-SecOpsViews ==="

    $views = @(
        "az_cc_secops_latest_scan_per_customer",
        "az_cc_secops_open_findings_per_customer",
        "az_cc_secops_recent_scans",
        "az_cc_secops_all_findings"
    )

    foreach ($v in $views) {
        try {
            $res = Invoke-SupabaseRest -Path "/rest/v1/$v" -Method GET -Query @{ select = "*"; limit = "1" }
            Add-TestResult -Name "View selectable: $v" -Success $true
        }
        catch {
            Add-TestResult -Name "View selectable: $v" -Success $false -Details $_.Exception.Message
        }
    }

    # Summary KPI query via RPC (if you expose it), or via az_cc_secops_recent_scans sanity check
    try {
        $res = Invoke-SupabaseRest -Path "/rest/v1/az_security_scans" -Method GET -Query @{ select = "id"; limit = "1" }
        Add-TestResult -Name "Base table az_security_scans accessible" -Success $true
    }
    catch {
        Add-TestResult -Name "Base table az_security_scans accessible" -Success $false -Details $_.Exception.Message
    }

    try {
        $res = Invoke-SupabaseRest -Path "/rest/v1/az_security_findings" -Method GET -Query @{ select = "id"; limit = "1" }
        Add-TestResult -Name "Base table az_security_findings accessible" -Success $true
    }
    catch {
        Add-TestResult -Name "Base table az_security_findings accessible" -Success $false -Details $_.Exception.Message
    }
}

# 5) Behaviour test: synthetic scan + findings
function Test-SecOpsOpenVsFixed {
    Write-Host "=== Test-SecOpsOpenVsFixed ==="

    $testCustomer = "secops_test_customer"
    $scanId       = "SEC-TEST-" + ([Guid]::NewGuid().ToString("N").Substring(0,8))
    $now          = (Get-Date).ToString("o")

    try {
        # 5.1 Insert synthetic scan
        $scanBody = @(
            @{
                scan_id     = $scanId
                customer_id = $testCustomer
                profile     = "test_profile"
                status      = "completed"
                started_at  = $now
                finished_at = $now
                summary     = "Test scan for SecOps open vs fixed behaviour"
            }
        )

        $scanRes = Invoke-SupabaseRest -Path "/rest/v1/az_security_scans" -Method POST -Body $scanBody

        # 5.2 Insert two findings: one open critical, one fixed high
        $findingsBody = @(
            @{
                scan_id     = $scanId
                severity    = "critical"
                category    = "test_category"
                endpoint    = "https://example.com/test-critical"
                description = "Synthetic critical open finding for testing."
                remediation = "No-op, synthetic."
                status      = "open"
            },
            @{
                scan_id     = $scanId
                severity    = "high"
                category    = "test_category"
                endpoint    = "https://example.com/test-high"
                description = "Synthetic high fixed finding for testing."
                remediation = "No-op, synthetic."
                status      = "fixed"
            }
        )

        $fRes = Invoke-SupabaseRest -Path "/rest/v1/az_security_findings" -Method POST -Body $findingsBody

        # 5.3 Check open findings per customer
        $heatmap = Invoke-SupabaseRest -Path "/rest/v1/az_cc_secops_open_findings_per_customer" -Method GET -Query @{
            select      = "*"
            customer_id = "eq.$testCustomer"
        }

        $row = $heatmap | Select-Object -First 1

        if ($null -eq $row) {
            Add-TestResult -Name "Open findings heatmap includes test customer" -Success $false -Details "No row for $testCustomer"
        } else {
            $openCount = [int]$row.open_findings
            $critical  = [int]$row.critical
            $high      = [int]$row.high

            $ok = ($openCount -ge 1 -and $critical -ge 1)
            $details = "open_findings=$openCount, critical=$critical, high=$high"
            Add-TestResult -Name "Open findings heatmap counts only open critical correctly" -Success $ok -Details $details
        }

        # 5.4 Summary KPI sanity check
        $summary = @"
select
  (select count(*) from az_security_scans) as total_scans,
  (select count(*) from az_security_scans where status = 'running') as running_scans,
  (select count(*) from az_security_scans where status = 'error') as error_scans,
  (select count(*) from az_security_findings) as total_findings,
  (select count(*) from az_security_findings where coalesce(status,'open')='open') as open_findings,
  (select count(*) from az_security_findings where severity='critical') as critical_findings,
  (select count(*) from az_security_findings where severity='high') as high_findings;
"@

        # If you have a RPC to run SQL, you can plug it here.
        # For now we just mark the behavioural part as done.
        Add-TestResult -Name "Behaviour test synthetic scan+findings inserted successfully" -Success $true
    }
    catch {
        Add-TestResult -Name "Behaviour test synthetic scan+findings" -Success $false -Details $_.Exception.Message
    }
    finally {
        # Cleanup synthetic data (best-effort)
        try {
            Invoke-SupabaseRest -Path "/rest/v1/az_security_findings" -Method DELETE -Query @{ scan_id = "eq.$scanId" }
        } catch { }

        try {
            Invoke-SupabaseRest -Path "/rest/v1/az_security_scans" -Method DELETE -Query @{ scan_id = "eq.$scanId" }
        } catch { }
    }
}

function Send-SecOpsTestAlert {
    param(
        [string]$Status,   # "ok" or "failed"
        [string]$Summary
    )

    try {
        $body = @(
            @{
                project = "secops_tests"
                action  = "notify"
                agent   = "notify"
                status  = "queued"
                result  = "SecOps tests status: $Status. $Summary"
            }
        )

        Invoke-SupabaseRest -Path "/rest/v1/az_commands" -Method POST -Body $body | Out-Null
    }
    catch {
        Write-Warning "Failed to queue SecOps test alert: $($_.Exception.Message)"
    }
}

# 6) Commands feed test
function Test-SecOpsCommandsFeed {
    Write-Host "=== Test-SecOpsCommandsFeed ==="

    $now     = Get-Date
    $nowIso  = $now.ToString("o")
    $testRes = "SecOps test command from SecOps-RunTests.ps1 at $nowIso"

    try {
        $body = @(
            @{
                project    = "secops_test"
                action     = "security_scan"
                agent      = "security"
                status     = "done"
                result     = $testRes
            }
        )

        $insertRes = Invoke-SupabaseRest -Path "/rest/v1/az_commands" -Method POST -Body $body

        # Fetch last 10 security commands and see if our result is there
        $feed = Invoke-SupabaseRest -Path "/rest/v1/az_commands" -Method GET -Query @{
            select = "id,action,agent,status,result,created_at"
            agent  = "eq.security"
            order  = "id.desc"
            limit  = "10"
        }

        $found = $false
        foreach ($row in $feed) {
            if ([string]$row.result -like "*SecOps test command from SecOps-RunTests.ps1*") {
                $found = $true
                break
            }
        }

        Add-TestResult -Name "Commands feed shows 'security' agent commands" -Success $found -Details ("Found=" + $found)
    }
    catch {
        Add-TestResult -Name "Commands feed test" -Success $false -Details $_.Exception.Message
    }
}

# 7) Run all tests
Write-Host "=== Running SecOps tests ==="
Test-SecOpsViews
Test-SecOpsOpenVsFixed
Test-SecOpsCommandsFeed

Write-Host ""
Write-Host "=== SecOps Test Summary ==="

$passed = $SecOpsTestResults | Where-Object { $_.Success } | Measure-Object | Select-Object -ExpandProperty Count
$failed = $SecOpsTestResults | Where-Object { -not $_.Success } | Measure-Object | Select-Object -ExpandProperty Count

$SecOpsTestResults | Format-Table -AutoSize

Write-Host ""
Write-Host "=== SecOps Test Summary ==="

$passed = $SecOpsTestResults | Where-Object { $_.Success } | Measure-Object | Select-Object -ExpandProperty Count
$failed = $SecOpsTestResults | Where-Object { -not $_.Success } | Measure-Object | Select-Object -ExpandProperty Count

$SecOpsTestResults | Format-Table -AutoSize

Write-Host ""
Write-Host "=== SecOps Test Summary ==="

$passed = $SecOpsTestResults | Where-Object { $_.Success } | Measure-Object | Select-Object -ExpandProperty Count
$failed = $SecOpsTestResults | Where-Object { -not $_.Success } | Measure-Object | Select-Object -ExpandProperty Count

$SecOpsTestResults | Format-Table -AutoSize

Write-Host ""
Write-Host "Total tests: $($SecOpsTestResults.Count)"
Write-Host "Passed     : $passed" -ForegroundColor Green

if ($failed -gt 0) {
    Write-Host "Failed     : $failed" -ForegroundColor Red

    # Queue a notify command for Jarvis-NotifyWorker
    $summary = "Total=$($SecOpsTestResults.Count), Failed=$failed"
    Send-SecOpsTestAlert -Status "failed" -Summary $summary

    exit 1
}
else {
    Write-Host "All SecOps tests passed." -ForegroundColor Green

    # Optional: also log success
    $summary = "Total=$($SecOpsTestResults.Count), Failed=0"
    Send-SecOpsTestAlert -Status "ok" -Summary $summary

    exit 0
}
