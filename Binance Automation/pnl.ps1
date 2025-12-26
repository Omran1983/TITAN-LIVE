. .\init.ps1 -Mode (Test-Path .\.env.prod) ? "prod" : "testnet"
$env:OUT_CSV="trades_export.csv"
python -m scripts.export_trades_csv | Out-Null
python -m scripts.kpi_from_csv
