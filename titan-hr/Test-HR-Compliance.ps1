$ErrorActionPreference = "Stop"
. "F:\AION-ZERO\scripts\Jarvis-LoadEnv.ps1"

Write-Host "=== TEST: TITAN-HR COMPLIANCE BLOCK ==="

# 1. Run Validator on Dummy Data
$scriptPath = "F:\AION-ZERO\titan-hr\Jarvis-HR-Validator.ps1"
$dummyPath = "F:\AION-ZERO\titan-hr\employees_dummy.csv"

if (-not (Test-Path $scriptPath)) { throw "Agent script missing!" }

Write-Host "Running Validator..."
& $scriptPath -SingleRun -InputPath $dummyPath

# 2. Check Result Artifact
$reportPath = "F:\AION-ZERO\titan-hr\compliance_report_$(Get-Date -Format 'yyyyMMdd').json"
if (Test-Path $reportPath) {
    $json = Get-Content $reportPath -Raw | ConvertFrom-Json
    Write-Host "`nAnalysis Result:"
    Write-Host "Score: $($json.compliance_score)%" -ForegroundColor Yellow
    Write-Host "Violations: $($json.violations.Count)" -ForegroundColor Red
    
    # Assertions
    if ($json.violations.Count -gt 0 -and $json.compliance_score -lt 100) {
        Write-Host "SUCCESS: Violations correctly detected." -ForegroundColor Green
    }
    else {
        Write-Error "FAIL: Expected violations were NOT detected."
    }
}
else {
    Write-Error "FAIL: Report artifact not created."
}
