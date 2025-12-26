param([string]$Date = (Get-Date -Format "yyyy-MM-dd"))
$ErrorActionPreference = "Stop"
$Base = (Resolve-Path -LiteralPath .).Path     # <-- SAME AS Start-JarvisPaper
$Journal = Join-Path $Base 'journal'
$Csv     = Join-Path $Journal ("paper_trades_{0}.csv" -f $Date)
if (-not (Test-Path $Csv)) { throw "No paper CSV for $Date at: $Csv" }

$rows = @(Import-Csv -Path $Csv)
$total = $rows.Count
$buys  = (@($rows | Where-Object side -eq 'BUY')).Count
$sells = (@($rows | Where-Object side -eq 'SELL')).Count

$bySym = $rows | Group-Object symbol
$netPnl = 0.0
foreach ($g in $bySym) {
  $buyQ = New-Object System.Collections.Queue
  foreach ($r in ($g.Group | Sort-Object ts_utc)) {
    if ($r.side -eq 'BUY') { $buyQ.Enqueue($r) }
    elseif ($r.side -eq 'SELL' -and $buyQ.Count -gt 0) {
      $b = $buyQ.Dequeue()
      $pnl = ([double]$r.notional_usdt - [double]$b.notional_usdt) - ([double]$r.fee_usdt + [double]$b.fee_usdt)
      $netPnl += $pnl
    }
  }
}

$outDir = Join-Path $Journal "reports"; New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$mdPath = Join-Path $outDir ("report_{0}.md" -f $Date)
$md = @(
  "# Jarvis Paper Report — $Date",
  "",
  "*Total rows:* **$total**",
  "*BUY:* $buys   |   *SELL:* $sells",
  ("*Approx Net PnL (USDT):* {0:N6}" -f $netPnl),
  "",
  "Source: $((Resolve-Path $Csv).Path)"
)
$md -join "`r`n" | Set-Content -Path $mdPath -Encoding UTF8
Write-Host "Wrote report: $mdPath"
