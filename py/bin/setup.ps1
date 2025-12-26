# HARD-CODED PATHS (no MyInvocation)
$ErrorActionPreference = "Stop"
$PyRoot = "F:\AION-ZERO\py"
$Venv   = Join-Path $PyRoot "venv"
$Req    = Join-Path $PyRoot "requirements.txt"

function Find-Python {
  foreach ($c in @("py","python","python3")) {
    & $c --version 1>$null 2>$null
    if ($LASTEXITCODE -eq 0) { return $c }
  }
  throw "Python not found. Install Python 3.11+ or add to PATH."
}

$PyExe = Find-Python

if (-not (Test-Path $Venv)) {
  Write-Host "Creating venv at $Venv ..." -ForegroundColor Cyan
  if ($PyExe -eq "py") {
    & $PyExe -3.11 -m venv $Venv; if ($LASTEXITCODE) { & $PyExe -3 -m venv $Venv }
  } else {
    & $PyExe -m venv $Venv
  }
}

$Vpy = Join-Path $Venv "Scripts\python.exe"
if (-not (Test-Path $Vpy)) { throw "venv python missing at $Vpy" }

& $Vpy -m pip install --upgrade pip setuptools wheel
if ($LASTEXITCODE -ne 0) { throw "pip upgrade failed" }

& $Vpy -m pip install -r $Req --retries 5 --timeout 60
if ($LASTEXITCODE -ne 0) { throw "pip install -r requirements.txt failed" }

Write-Host "Dependencies installed." -ForegroundColor Green
