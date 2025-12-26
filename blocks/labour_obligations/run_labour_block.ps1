$ErrorActionPreference = "Stop"

# 1. Define Paths
$BasePath = "F:\AION-ZERO\blocks\labour_obligations"
$InputFile = Join-Path $BasePath "inputs\filings_dummy.csv"
$Validator = Join-Path $BasePath "validate_labour.py"

# 2. Check Input
if (-not (Test-Path $InputFile)) {
    Write-Error "Input file not found: $InputFile"
}

# 3. Run Validator
Write-Host "🚀 Running TITAN-LABOUR Block..." -ForegroundColor Cyan
python $Validator --input $InputFile

# 4. Check Exit Code
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ [SUCCESS] All Obligations Met." -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`n⚠️ [WARNING] Deadlines Missed or Unpaid." -ForegroundColor Red
    exit 1
}
