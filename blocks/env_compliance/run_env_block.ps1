<#
.SYNOPSIS
    TITAN-ENV Block Runner
    Executes Environmental Compliance Checks.
#>

param(
    [string]$InputFile = "$PSScriptRoot\inputs\env_log_dummy.csv"
)

$ErrorActionPreference = "Stop"
$BlockRoot = $PSScriptRoot
$PythonScript = "$BlockRoot\validate_environment.py"

Write-Host "==========================================" -ForegroundColor Green
Write-Host " 🌿 TITAN-ENV COMPLIANCE BLOCK " -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Green

if (-not (Test-Path $InputFile)) {
    Write-Error "Input not found: $InputFile"
}

python $PythonScript --input $InputFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[SUCCESS] Environment Compliant." -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`n[WARNING] Environmental Risks Detected." -ForegroundColor Red
    exit 1
}
