param(
  [string]$LogsGlob = ".\logs\live_*.log",
  [int]$RefreshSec = 5
)

$ErrorActionPreference = "SilentlyContinue"
$proj = Split-Path -Parent $MyInvocation.MyCommand.Path
$py   = Join-Path $proj ".venv\Scripts\python.exe"

# --- Regex (tune if your logs differ) ---
$reOpen = 'OPEN|Opened|ENTER|BUY|SELL'
$reFill = 'FILLED|filled'
$reExit = 'CLOSE|Exit|TP hit|SL hit|stop|take-profit'
$reErr  = 'ERROR|ClientError|429|-2015|insufficient|reject|throttle'

# PnL scanners (USDT/USD preferred; % tracked separately)
$rePnLusd = 'PnL[^0-9+\-]*([+\-]?\d+(?:\.\d+)?)\s*(?:USDT|USD)\b'
$rePnLpct = 'PnL[^0-9+\-]*([+\-]?\d+(?:\.\d+)?)\s*%'

# Try to pull a symbol like XYZUSDT from the line
$reSym = '([A-Z0-9]{2,12}USDT)'

# Track last-read offsets so we only process deltas
$offsets = @{}  # path -> last length processed

function Get-EquityUSDT {
  $prev = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $env:ENV_FILE = ".env.mainnet"
    $out = & $py -m scripts.list_balances 2>&1
    $line = $out | Where-Object { $_ -match '^\s*USDT\s+free=' } | Select-Object -First 1
    if ($line -and $line -match 'free=([0-9\.]+)') { return [double]$Matches[1] }
    return [double]0
  } catch {
    return [double]0
  } finally { $ErrorActionPreference = $prev }
}

function Scan-Deltas {
  # Returns a hashtable of accumulated metrics from NEW lines only
  $files = Get-ChildItem -Path $LogsGlob -ErrorAction SilentlyContinue
  $metrics = @{
    opens = 0; fills = 0; exits = 0; errors = 0;
    pnl_usd = 0.0; pnl_pct = 0.0;
    pnl_usd_count = 0; pnl_pct_count = 0;
    bySymbol = @{}  # sym -> [activity count]
  }

  foreach ($f in $files) {
    $p = $f.FullName
    $last = 0L
    if ($offsets.ContainsKey($p)) { $last = [long]$offsets[$p] }
    $lenNow = [long]$f.Length
    if ($lenNow -le $last) { continue }

    # Read just the delta tail
    $fs = [System.IO.File]::Open($p, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
      [void]$fs.Seek($last, [System.IO.SeekOrigin]::Begin)
      $sr = New-Object System.IO.StreamReader($fs)
      $chunk = $sr.ReadToEnd()
      $sr.Close()
    } finally { $fs.Close() }

    $offsets[$p] = $lenNow
    if (-not $chunk) { continue }

    $lines = $chunk -split "`r?`n"
    foreach ($line in $lines) {
      if (-not $line) { continue }

      $sym = $null
      if ($line -match $reSym) { $sym = $Matches[1] }

      if ($line -match $reOpen) { $metrics.opens++; if ($sym) { if (-not $metrics.bySymbol.ContainsKey($sym)) { $metrics.bySymbol[$sym]=0 }; $metrics.bySymbol[$sym]++ } }
      if ($line -match $reFill) { $metrics.fills++; if ($sym) { if (-not $metrics.bySymbol.ContainsKey($sym)) { $metrics.bySymbol[$sym]=0 }; $metrics.bySymbol[$sym]++ } }
      if ($line -match $reExit) { $metrics.exits++; if ($sym) { if (-not $metrics.bySymbol.ContainsKey($sym)) { $metrics.bySymbol[$sym]=0 }; $metrics.bySymbol[$sym]++ } }
      if ($line -match $reErr)  { $metrics.errors++ }

      if ($line -match $rePnLusd) {
        $pnl = [double]$Matches[1]
        $metrics.pnl_usd += $pnl
        $metrics.pnl_usd_count++
      } elseif ($line -match $rePnLpct) {
        $pp = [double]$Matches[1]
        $metrics.pnl_pct += $pp
        $metrics.pnl_pct_count++
      }
    }
  }
  return $metrics
}

function Print-Table($title, $rows) {
  Write-Host ("`n{0}" -f $title) -ForegroundColor Cyan
  Write-Host ("{0}" -f ('-' * [math]::Max(10, $title.Length)))
  foreach ($r in $rows) { Write-Host $r }
}

# Running totals since dashboard start
$total = @{
  opens = 0; fills = 0; exits = 0; errors = 0;
  pnl_usd = 0.0; pnl_pct = 0.0;
  pnl_usd_count = 0; pnl_pct_count = 0;
  bySymbol = @{}
}

while ($true) {
  $metrics = Scan-Deltas

  # accumulate totals
  foreach ($k in "opens","fills","exits","errors","pnl_usd","pnl_pct","pnl_usd_count","pnl_pct_count") {
    if ($metrics.ContainsKey($k)) {
      if (($k -eq "pnl_usd") -or ($k -eq "pnl_pct")) {
        $total[$k] = [double]$total[$k] + [double]$metrics[$k]
      } else {
        $total[$k] = [int]$total[$k] + [int]$metrics[$k]
      }
    }
  }
  foreach ($sym in $metrics.bySymbol.Keys) {
    if (-not $total.bySymbol.ContainsKey($sym)) { $total.bySymbol[$sym] = 0 }
    $total.bySymbol[$sym] = [int]$total.bySymbol[$sym] + [int]$metrics.bySymbol[$sym]
  }

  # compute derivatives
  $winRateTxt = "—"
  if ($total.exits -gt 0 -and $total.pnl_usd_count -gt 0) {
    # crude heuristic: if total pnl_usd positive, show that; win rate needs exact win/lose flags which we might not have
    $winRateTxt = "n/a"
  }
  $avgPnlUsdTxt = ($total.pnl_usd_count -gt 0) ? ("{0:N4}" -f ([double]$total.pnl_usd / [double]$total.pnl_usd_count)) : "—"
  $avgPnlPctTxt = ($total.pnl_pct_count -gt 0) ? ("{0:N3}%" -f ([double]$total.pnl_pct / [double]$total.pnl_pct_count)) : "—"

  $eq = Get-EquityUSDT

  Clear-Host
  Write-Host "====================  JARVIS LIVE DASHBOARD  ====================" -ForegroundColor Green
  Write-Host ("Time: {0}    Equity (Spot USDT free): {1:N2}" -f (Get-Date), $eq)

  $headline = @(
    ("Opens : {0}" -f $total.opens),
    ("Fills : {0}" -f $total.fills),
    ("Exits : {0}" -f $total.exits),
    ("Errors: {0}" -f $total.errors),
    ("PnL Σ (USDT): {0:N4}" -f [double]$total.pnl_usd),
    ("Avg PnL/trade (USDT): {0}" -f $avgPnlUsdTxt),
    ("Avg PnL% (if present): {0}" -f $avgPnlPctTxt)
  )
  Print-Table "Session KPIs" $headline

  # Top symbols by activity
  $symRows = @()
  if ($total.bySymbol.Keys.Count -gt 0) {
    $pairs = @()
    foreach ($k in $total.bySymbol.Keys) { $pairs += ,@($k, [int]$total.bySymbol[$k]) }
    $pairs = $pairs | Sort-Object @{Expression={$_[1]}; Ascending=$false}
    $top = $pairs | Select-Object -First 5
    foreach ($p in $top) { $symRows += ("{0,-12}  activity:{1}" -f $p[0], $p[1]) }
  } else {
    $symRows += "No symbol activity yet."
  }
  Print-Table "Top Symbols (activity score)" $symRows

  Write-Host "`n(Refreshes every $RefreshSec s. Ctrl+C to quit.)"
  Start-Sleep -Seconds $RefreshSec
}
