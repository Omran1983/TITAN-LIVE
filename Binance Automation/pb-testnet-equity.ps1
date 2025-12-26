param([double]$CashIn = 0)
$env:ENV_FILE = ".env.testnet"
& .\.venv\Scripts\python.exe -m scripts.equity_pnl_now --cash-in $CashIn
