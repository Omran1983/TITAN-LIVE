<#
.SYNOPSIS
    TITAN-HR Block Runner
    Executes the Compliance Block for PRB-2026.

.DESCRIPTION
    1. Checks environment.
    2. Runs Validator against input.
    3. Returns Exit Code (0 = Compliant, 1 = Risk Detected).
#>

param(
    [string]$InputFile = "$PSScriptRoot\employees_dummy.csv"
)

$ErrorActionPreference = "Stop"
$BlockRoot = $PSScriptRoot
$PythonScript = "$BlockRoot\validate_employees.py"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " 🦅 TITAN-HR COMPLIANCE BLOCK " -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Target Input: $InputFile"

if (-not (Test-Path $InputFile)) {
    Write-Error "Input file not found: $InputFile"
}

# Execute Python Validator
Write-Host ">>> Executing Logic Layer..." -ForegroundColor Gray
python $PythonScript --input $InputFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[SUCCESS] No Compliance Risks Detected." -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`n[WARNING] Compliance Risks Detected. Check Report." -ForegroundColor Red
    exit 1
}
