param([ValidateSet("testnet","prod")]$Mode="testnet",[string]$Symbol="BTCUSDT")
if ($Mode -eq "prod") { $env:ENV_FILE = ".env.prod" } else { $env:ENV_FILE = ".env.testnet" }
if (-not (Test-Path ".\.venv\Scripts\Activate.ps1")) { python -m venv .venv }
& ".\.venv\Scripts\Activate.ps1" | Out-Null
$env:PYTHONPATH = (Get-Location).Path
$env:SYMBOL = $Symbol
$env:RECV_WINDOW = "5000"
Write-Host "[init] mode=$Mode symbol=$Symbol ENV_FILE=$env:ENV_FILE"
