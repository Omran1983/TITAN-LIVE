param(
  [Parameter(Position=0)][string]$Cmd = "ping",
  [Parameter(Position=1)][string]$Arg1,
  [Parameter(Position=2)][string]$Arg2
)
$ErrorActionPreference = "Stop"
$env:PYTHONUTF8 = 1

# HARD-CODED ROOTS
$PyRoot = "F:\AION-ZERO\py"
$venvPy = Join-Path (Join-Path $PyRoot "venv") "Scripts\python.exe"

if (-not (Test-Path $venvPy)) { throw "venv python not found. Run F:\AION-ZERO\py\bin\setup.ps1 first." }

# Build argv and run as MODULE so relative imports work
$argv = @($Cmd)
if ($PSBoundParameters.ContainsKey("Arg1")) { $argv += $Arg1 }
if ($PSBoundParameters.ContainsKey("Arg2")) { $argv += $Arg2 }

Push-Location $PyRoot
try {
  & $venvPy -m aogrl_ops_pack.cli @argv
  $code = $LASTEXITCODE
} finally {
  Pop-Location
}

Write-Host ("[launcher] command='{0}' code={1}" -f $Cmd, $code) -ForegroundColor Cyan
$global:LASTEXITCODE = $code