param(
  [double]$CashIn
)
if (-not $PSBoundParameters.ContainsKey("CashIn")) {
  $CashIn = [double](Read-Host "Enter CASH_IN in USDT (total net deposits)")
}
$env:ENV_FILE = ".env.mainnet"
& .\.venv\Scripts\python.exe -m scripts.equity_pnl_now --cash-in $CashIn
