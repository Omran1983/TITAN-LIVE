param(
  [string]$symbol="BTCUSDT",
  [double]$quote=5,
  [int]$trades=5,
  [int]$delaySec=4,
  [int]$autoSellSec=6,     # 0 = no auto market-exit
  [double]$sellFrac=1.0    # 1.0 = exit 100% of just-bought qty (best-effort)
)
. .\init.ps1 -Mode (Test-Path .\.env.prod) ? "prod" : "testnet" -Symbol $symbol

for ($i=1; $i -le $trades; $i++) {
  Write-Host "[scalp] BUY #$i quote=$quote $symbol"
  $env:QUOTE_QTY = [string]$quote
  python -m scripts.run_live_trade_safe

  if ($autoSellSec -gt 0) {
    Start-Sleep -Seconds $autoSellSec
    Write-Host "[scalp] AUTO-EXIT #$i sellFrac=$sellFrac"
    # Best effort: sell fraction of base balance quickly
    .\flat.ps1 -symbol $symbol -sellPct ([math]::Round($sellFrac*100,2)) | Out-Null
  }

  if ($i -lt $trades) { Start-Sleep -Seconds $delaySec }
}
Write-Host "[scalp] done."
