param([string]$Date = (Get-Date -Format "yyyy-MM-dd"))
$ErrorActionPreference = "Stop"
$Base = (Resolve-Path -LiteralPath .).Path     # <-- SAME AS Start-JarvisPaper
$Journal = Join-Path $Base 'journal'
$Csv     = Join-Path $Journal ("paper_trades_{0}.csv" -f $Date)

if (-not (Test-Path $Csv)) {
  Write-Host "Closed=0 | WinRate=0% | MedianEdgeBps=0 | NetPnL=0.000000 USDT"
  exit 0
}

$rows = @(Import-Csv -Path $Csv)
$closed = @($rows | Where-Object side -eq 'SELL')
$closedCount = $closed.Count

$edgeVals = @()
foreach ($r in $closed) {
  $slip = 0; [void][double]::TryParse($r.slippage_bps, [ref]$slip)
  $edgeVals += (0 - $slip)
}
$medianEdge = 0
if ($edgeVals.Count -gt 0) {
  $sorted = @($edgeVals | Sort-Object)
  $n = $sorted.Count
  if ($n % 2 -eq 1) { $medianEdge = $sorted[([int][math]::Floor($n/2))] }
  else { $medianEdge = ([double]($sorted[$n/2-1] + $sorted[$n/2]) / 2.0) }
}

$bySym = $rows | Group-Object symbol
$wins = 0; $losses = 0; $netPnl = 0.0
foreach ($g in $bySym) {
  $buyQ = New-Object System.Collections.Queue
  foreach ($r in ($g.Group | Sort-Object ts_utc)) {
    if ($r.side -eq 'BUY') { $buyQ.Enqueue($r) }
    elseif ($r.side -eq 'SELL' -and $buyQ.Count -gt 0) {
      $b = $buyQ.Dequeue()
      $pnl = ([double]$r.notional_usdt - [double]$b.notional_usdt) - ([double]$r.fee_usdt + [double]$b.fee_usdt)
      $netPnl += $pnl
      if ($pnl -gt 0) { $wins++ } else { $losses++ }
    }
  }
}
$wr = if (($wins + $losses) -gt 0) { 100.0 * $wins / ($wins+$losses) } else { 0.0 }

Write-Host ("Closed={0} | WinRate={1:N2}% | MedianEdgeBps={2} | NetPnL={3:N6} USDT" -f `
  $closedCount, $wr, [int][math]::Round($medianEdge), $netPnl)
