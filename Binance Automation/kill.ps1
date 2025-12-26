param([string]$symbol="BTCUSDT")
. .\init.ps1 -Mode (Test-Path .\.env.prod) ? "prod" : "testnet" -Symbol $symbol
python -m scripts.open_and_cancel_safe
