# Jarvis Hybrid Live: Meme coins, adaptive hold via your live runner, dynamic sizing 5Ã¢â€ â€™10%, cadence 8s/12s, drawdown stop -2.5%
param(
  [string]$EnvFile = ".env.mainnet",
  [double]$MinBookDepthUSD = 50000,      # skip illiquid books
  [double]$MaxSpreadBps    = 6,          # skip wide spreads
  [int]   $ReselectMinutes = 10,         # rotate top symbols every N minutes
  [int]   $MaxConcurrent   = 3           # positions concurrently (your OK)
)

$ErrorActionPreference = "Stop"
$proj = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $proj
$statePath = Join-Path $proj "state\jarvis_state.json"
$logDir    = Join-Path $proj "logs"

# Candidate meme pairs on Binance
$candidates = @("DOGEUSDT","SHIBUSDT","PEPEUSDT","FLOKIUSDT","BONKUSDT","WIFUSDT")

function Get-Json { param($obj) return ($obj | ConvertTo-Json -Depth 6) }
function Read-State {
  if (Test-Path $statePath) { try { Get-Content $statePath -Raw | ConvertFrom-Json } catch { @{} } } else { @{} }
}
function Write-State { param($s) $s | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 -LiteralPath $statePath }

function Get-PublicStats {
  param([string]$Sym)
  $base = "https://api.binance.com"
  # 24h stats (quoteVolume), bookTicker (spread), recent klines for vol
  $t24  = Invoke-RestMethod "$base/api/v3/ticker/24hr?symbol=$Sym"
  $bt   = Invoke-RestMethod "$base/api/v3/ticker/bookTicker?symbol=$Sym"
  $kl   = Invoke-RestMethod "$base/api/v3/klines?symbol=$Sym&interval=1m&limit=30"

  $bid  = [double]$bt.bidPrice
  $ask  = [double]$bt.askPrice
  $mid  = ($bid + $ask)/2
  $spread_bps = if ($mid -ne 0) { ( ($ask - $bid)/$mid ) * 10000 } else { 9999 }

  # Rough volatility proxy: avg abs( close-to-close returns )
  $rets = @()
  for ($i=1; $i -lt $kl.Count; $i++) {
    $p0 = [double]$kl[$i-1][4]; $p1 = [double]$kl[$i][4]
    if ($p0 -gt 0) { $rets += [math]::Abs(($p1-$p0)/$p0) }
  }
  $vol_bps = if ($rets.Count) { ([double]($rets | Measure-Object -Average).Average) * 10000 } else { 0 }

  # Approx book depth proxy from 24h quote volume / 1440, fallback min
  $qVol = [double]$t24.quoteVolume
  $avgMinQuote = $qVol / 1440.0
  $depth_ok = ($avgMinQuote -ge $MinBookDepthUSD)

  [pscustomobject]@{
    symbol     = $Sym
    spread_bps = [math]::Round($spread_bps,2)
    vol_bps    = [math]::Round($vol_bps,2)
    qvol_usd_m = [math]::Round($qVol/1e6,2)
    depth_ok   = $depth_ok
  }
}

function Score-Symbol {
  param($st)
  # Higher vol & volume is better, lower spread is better
  $score = ( [math]::Min($st.vol_bps, 120) ) + ( [math]::Min($st.qvol_usd_m, 50) * 2 ) - ( [math]::Min($st.spread_bps, 15) * 2 )
  return [math]::Round($score,2)
}

function Get-TopSymbols {
  $stats = @()
  foreach ($s in $candidates) {
    try {
      $st = Get-PublicStats -Sym $s
      if ($st.depth_ok -and ($st.spread_bps -le $MaxSpreadBps)) {
        $st | Add-Member -NotePropertyName score -NotePropertyValue (Score-Symbol $st)
        $stats += $st
      }
    } catch {
      Write-Host "[WARN] Stats failed for $s : $($_.Exception.Message)" -ForegroundColor Yellow
    }
  }
  $top = $stats | Sort-Object score -Descending | Select-Object -First $MaxConcurrent
  return ,($top)
}

function Get-EquityUSDT {
  param()
  $prevEAP = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $env:ENV_FILE = $EnvFile
    # Merge stderr into stdout so PS doesn't treat it as an error
    $out = & .\.venv\Scripts\python.exe -m scripts.list_balances 2>&1
    # Find the USDT line and extract 'free=' value
    $line = ($out | Where-Object { # Jarvis Hybrid Live: Meme coins, adaptive hold via your live runner, dynamic sizing 5Ã¢â€ â€™10%, cadence 8s/12s, drawdown stop -2.5%
param(
  [string]$EnvFile = ".env.mainnet",
  [double]$MinBookDepthUSD = 50000,      # skip illiquid books
  [double]$MaxSpreadBps    = 6,          # skip wide spreads
  [int]   $ReselectMinutes = 10,         # rotate top symbols every N minutes
  [int]   $MaxConcurrent   = 3           # positions concurrently (your OK)
)

$ErrorActionPreference = "Stop"
$proj = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $proj
$statePath = Join-Path $proj "state\jarvis_state.json"
$logDir    = Join-Path $proj "logs"

# Candidate meme pairs on Binance
$candidates = @("DOGEUSDT","SHIBUSDT","PEPEUSDT","FLOKIUSDT","BONKUSDT","WIFUSDT")

function Get-Json { param($obj) return ($obj | ConvertTo-Json -Depth 6) }
function Read-State {
  if (Test-Path $statePath) { try { Get-Content $statePath -Raw | ConvertFrom-Json } catch { @{} } } else { @{} }
}
function Write-State { param($s) $s | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 -LiteralPath $statePath }

function Get-PublicStats {
  param([string]$Sym)
  $base = "https://api.binance.com"
  # 24h stats (quoteVolume), bookTicker (spread), recent klines for vol
  $t24  = Invoke-RestMethod "$base/api/v3/ticker/24hr?symbol=$Sym"
  $bt   = Invoke-RestMethod "$base/api/v3/ticker/bookTicker?symbol=$Sym"
  $kl   = Invoke-RestMethod "$base/api/v3/klines?symbol=$Sym&interval=1m&limit=30"

  $bid  = [double]$bt.bidPrice
  $ask  = [double]$bt.askPrice
  $mid  = ($bid + $ask)/2
  $spread_bps = if ($mid -ne 0) { ( ($ask - $bid)/$mid ) * 10000 } else { 9999 }

  # Rough volatility proxy: avg abs( close-to-close returns )
  $rets = @()
  for ($i=1; $i -lt $kl.Count; $i++) {
    $p0 = [double]$kl[$i-1][4]; $p1 = [double]$kl[$i][4]
    if ($p0 -gt 0) { $rets += [math]::Abs(($p1-$p0)/$p0) }
  }
  $vol_bps = if ($rets.Count) { ([double]($rets | Measure-Object -Average).Average) * 10000 } else { 0 }

  # Approx book depth proxy from 24h quote volume / 1440, fallback min
  $qVol = [double]$t24.quoteVolume
  $avgMinQuote = $qVol / 1440.0
  $depth_ok = ($avgMinQuote -ge $MinBookDepthUSD)

  [pscustomobject]@{
    symbol     = $Sym
    spread_bps = [math]::Round($spread_bps,2)
    vol_bps    = [math]::Round($vol_bps,2)
    qvol_usd_m = [math]::Round($qVol/1e6,2)
    depth_ok   = $depth_ok
  }
}

function Score-Symbol {
  param($st)
  # Higher vol & volume is better, lower spread is better
  $score = ( [math]::Min($st.vol_bps, 120) ) + ( [math]::Min($st.qvol_usd_m, 50) * 2 ) - ( [math]::Min($st.spread_bps, 15) * 2 )
  return [math]::Round($score,2)
}

function Get-TopSymbols {
  $stats = @()
  foreach ($s in $candidates) {
    try {
      $st = Get-PublicStats -Sym $s
      if ($st.depth_ok -and ($st.spread_bps -le $MaxSpreadBps)) {
        $st | Add-Member -NotePropertyName score -NotePropertyValue (Score-Symbol $st)
        $stats += $st
      }
    } catch {
      Write-Host "[WARN] Stats failed for $s : $($_.Exception.Message)" -ForegroundColor Yellow
    }
  }
  $top = $stats | Sort-Object score -Descending | Select-Object -First $MaxConcurrent
  return ,($top)
}

function Get-EquityUSDT {
  param()
  \ = \Continue
  try {
    \Continue = 'Continue'
    \.env.mainnet = \
    # Merge stderr into stdout so PowerShell doesn't treat it as an error
    \System.IO.FileStream = & .\.venv\Scripts\python.exe -m scripts.list_balances 2>&1
    # Find the USDT line and extract 'free=' value
    \42 = (\System.IO.FileStream | Where-Object { \ -match '^\s*USDT\s+free=' } | Select-Object -First 1)
    if (\42 -and \42 -match 'free=([0-9\.]+)') { return [double]\[1] }
    else { return 0.0 }
  } catch {
    Write-Host "[WARN] Equity probe failed: " -ForegroundColor Yellow
    return 0.0
  } finally {
    \Continue = \
  }
} | Select-Object -First 1)
  if ($line) {
    if ($line -match 'free=([0-9\.]+)') { return [double]$Matches[1] }
  }
  return 0.0
}

function Decide-PositionPct {
  # 5% baseline, climb toward 10% when equity > baseline, back off to 5% if not
  $st = Read-State
  if (-not $st.baseline_equity) {
    $st.baseline_equity = [double](Get-EquityUSDT)
    if ($st.baseline_equity -le 0) { $st.baseline_equity = 100.0 }
    $st.pos_pct = 5.0
    Write-State $st
  }
  $eq = [double](Get-EquityUSDT)
  if ($eq -gt 0) {
    $chg = ($eq - $st.baseline_equity) / $st.baseline_equity
    if ($chg -ge 0.03) {
      $st.pos_pct = [math]::Min(10.0, $st.pos_pct + 0.5)
      $st.baseline_equity = $eq  # move the goalpost after step up
      Write-State $st
    } elseif ($chg -lt -0.02) {
      $st.pos_pct = 5.0
      $st.baseline_equity = $eq
      Write-State $st
    }
  }
  return [double]$((Read-State).pos_pct)
}

function Decide-CadenceSec {
  param($topStats)
  # If avg vol of top set > 60 bps Ã¢â€ â€™ 8s, else 12s
  if (-not $topStats -or $topStats.Count -eq 0) { return 12 }
  $avgVol = [double](($topStats | Measure-Object -Property vol_bps -Average).Average)
  return ($(if ($avgVol -ge 60) { 8 } else { 12 }))
}

function Drawdown-Hit {
  # Use equity snapshot file to track intraday drawdown vs open-of-day
  $st = Read-State
  $utcDay = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
  if ($st.dd_day -ne $utcDay) {
    $st.dd_day = $utcDay
    $st.dd_open_eq = [double](Get-EquityUSDT)
    $st.dd_tripped = $false
    Write-State $st
    return $false
  }
  $eqNow = [double](Get-EquityUSDT)
  if ($st.dd_open_eq -gt 0) {
    $dd = ($eqNow - $st.dd_open_eq) / $st.dd_open_eq
    if ($dd -le -0.025) { $st.dd_tripped = $true; Write-State $st }
  }
  return [bool]$((Read-State).dd_tripped)
}

# Main supervisor loop
while ($true) {
  if (Test-Path ".\KILL.TRADING") { Write-Host "[ABORT] Kill-switch present." -ForegroundColor Red; break }
  if (Drawdown-Hit) { Write-Host "[PAUSE] Intraday drawdown -2.5% hit. Cooling until UTC reset." -ForegroundColor Yellow; Start-Sleep -Seconds 60; continue }

  $top = Get-TopSymbols
  if (-not $top -or $top.Count -eq 0) { Write-Host "[WAIT] No eligible symbols now." -ForegroundColor Yellow; Start-Sleep -Seconds 30; continue }

  $posPct   = Decide-PositionPct
  $eqUSDT   = [double](Get-EquityUSDT)
  if ($eqUSDT -le 0) { Write-Host "[WAIT] No USDT free." -ForegroundColor Yellow; Start-Sleep -Seconds 30; continue }

  $cadence  = Decide-CadenceSec -topStats $top
  $tp       = 0.6   # hybrid: tighten on bursts, allow tails
  $sl       = 0.5

  Write-Host "[PICK] Top $($top.Count): " -NoNewline
  $top.symbol -join ", " | Write-Host -ForegroundColor Cyan
  Write-Host ("[PARAM] equity={0:F2} USDT  pos%={1:F2}%  cadence={2}s  TP={3}% SL={4}%" -f $eqUSDT,$posPct,$cadence,$tp,$sl)

  # Launch/refresh runners for each picked symbol (one per symbol)
  foreach ($row in $top) {
    $sym = $row.symbol
    $quote = [math]::Max([math]::Round($eqUSDT * ($posPct/100.0),2), 10.0) # min $10
    $log  = Join-Path $logDir ("live_{0}_{1}.log" -f $sym, (Get-Date -f "yyyyMMdd_HHmm"))

    $args = "--symbol $sym --quote $quote --tp $tp --sl $sl --every $cadence --max-trades $MaxConcurrent"
    . .\pb-run-module-guarded.ps1 -Module "scripts.run_live_trade_safe" -Args $args -EnvFile $EnvFile -LogFile $log
  }

  # Sleep until next reselection window; runners keep working
  for ($i=0; $i -lt ($ReselectMinutes*60); $i+=10) {
    if (Test-Path ".\KILL.TRADING") { Write-Host "[ABORT] Kill-switch present." -ForegroundColor Red; break }
    if (Drawdown-Hit) { Write-Host "[PAUSE] Drawdown hit, skipping new spawns." -ForegroundColor Yellow }
    Start-Sleep -Seconds 10
  }
}
 -match '^\s*USDT\s+free=' } | Select-Object -First 1)
    if ($line -and $line -match 'free=([0-9\.]+)') { return [double]$Matches[1] }
    else { return 0.0 }
  } catch {
    Write-Host ("[WARN] Equity probe failed: {0}" -f (# Jarvis Hybrid Live: Meme coins, adaptive hold via your live runner, dynamic sizing 5Ã¢â€ â€™10%, cadence 8s/12s, drawdown stop -2.5%
param(
  [string]$EnvFile = ".env.mainnet",
  [double]$MinBookDepthUSD = 50000,      # skip illiquid books
  [double]$MaxSpreadBps    = 6,          # skip wide spreads
  [int]   $ReselectMinutes = 10,         # rotate top symbols every N minutes
  [int]   $MaxConcurrent   = 3           # positions concurrently (your OK)
)

$ErrorActionPreference = "Stop"
$proj = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $proj
$statePath = Join-Path $proj "state\jarvis_state.json"
$logDir    = Join-Path $proj "logs"

# Candidate meme pairs on Binance
$candidates = @("DOGEUSDT","SHIBUSDT","PEPEUSDT","FLOKIUSDT","BONKUSDT","WIFUSDT")

function Get-Json { param($obj) return ($obj | ConvertTo-Json -Depth 6) }
function Read-State {
  if (Test-Path $statePath) { try { Get-Content $statePath -Raw | ConvertFrom-Json } catch { @{} } } else { @{} }
}
function Write-State { param($s) $s | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 -LiteralPath $statePath }

function Get-PublicStats {
  param([string]$Sym)
  $base = "https://api.binance.com"
  # 24h stats (quoteVolume), bookTicker (spread), recent klines for vol
  $t24  = Invoke-RestMethod "$base/api/v3/ticker/24hr?symbol=$Sym"
  $bt   = Invoke-RestMethod "$base/api/v3/ticker/bookTicker?symbol=$Sym"
  $kl   = Invoke-RestMethod "$base/api/v3/klines?symbol=$Sym&interval=1m&limit=30"

  $bid  = [double]$bt.bidPrice
  $ask  = [double]$bt.askPrice
  $mid  = ($bid + $ask)/2
  $spread_bps = if ($mid -ne 0) { ( ($ask - $bid)/$mid ) * 10000 } else { 9999 }

  # Rough volatility proxy: avg abs( close-to-close returns )
  $rets = @()
  for ($i=1; $i -lt $kl.Count; $i++) {
    $p0 = [double]$kl[$i-1][4]; $p1 = [double]$kl[$i][4]
    if ($p0 -gt 0) { $rets += [math]::Abs(($p1-$p0)/$p0) }
  }
  $vol_bps = if ($rets.Count) { ([double]($rets | Measure-Object -Average).Average) * 10000 } else { 0 }

  # Approx book depth proxy from 24h quote volume / 1440, fallback min
  $qVol = [double]$t24.quoteVolume
  $avgMinQuote = $qVol / 1440.0
  $depth_ok = ($avgMinQuote -ge $MinBookDepthUSD)

  [pscustomobject]@{
    symbol     = $Sym
    spread_bps = [math]::Round($spread_bps,2)
    vol_bps    = [math]::Round($vol_bps,2)
    qvol_usd_m = [math]::Round($qVol/1e6,2)
    depth_ok   = $depth_ok
  }
}

function Score-Symbol {
  param($st)
  # Higher vol & volume is better, lower spread is better
  $score = ( [math]::Min($st.vol_bps, 120) ) + ( [math]::Min($st.qvol_usd_m, 50) * 2 ) - ( [math]::Min($st.spread_bps, 15) * 2 )
  return [math]::Round($score,2)
}

function Get-TopSymbols {
  $stats = @()
  foreach ($s in $candidates) {
    try {
      $st = Get-PublicStats -Sym $s
      if ($st.depth_ok -and ($st.spread_bps -le $MaxSpreadBps)) {
        $st | Add-Member -NotePropertyName score -NotePropertyValue (Score-Symbol $st)
        $stats += $st
      }
    } catch {
      Write-Host "[WARN] Stats failed for $s : $($_.Exception.Message)" -ForegroundColor Yellow
    }
  }
  $top = $stats | Sort-Object score -Descending | Select-Object -First $MaxConcurrent
  return ,($top)
}

function Get-EquityUSDT {
  param()
  \ = \Continue
  try {
    \Continue = 'Continue'
    \.env.mainnet = \
    # Merge stderr into stdout so PowerShell doesn't treat it as an error
    \System.IO.FileStream = & .\.venv\Scripts\python.exe -m scripts.list_balances 2>&1
    # Find the USDT line and extract 'free=' value
    \42 = (\System.IO.FileStream | Where-Object { \ -match '^\s*USDT\s+free=' } | Select-Object -First 1)
    if (\42 -and \42 -match 'free=([0-9\.]+)') { return [double]\[1] }
    else { return 0.0 }
  } catch {
    Write-Host "[WARN] Equity probe failed: " -ForegroundColor Yellow
    return 0.0
  } finally {
    \Continue = \
  }
} | Select-Object -First 1)
  if ($line) {
    if ($line -match 'free=([0-9\.]+)') { return [double]$Matches[1] }
  }
  return 0.0
}

function Decide-PositionPct {
  # 5% baseline, climb toward 10% when equity > baseline, back off to 5% if not
  $st = Read-State
  if (-not $st.baseline_equity) {
    $st.baseline_equity = [double](Get-EquityUSDT)
    if ($st.baseline_equity -le 0) { $st.baseline_equity = 100.0 }
    $st.pos_pct = 5.0
    Write-State $st
  }
  $eq = [double](Get-EquityUSDT)
  if ($eq -gt 0) {
    $chg = ($eq - $st.baseline_equity) / $st.baseline_equity
    if ($chg -ge 0.03) {
      $st.pos_pct = [math]::Min(10.0, $st.pos_pct + 0.5)
      $st.baseline_equity = $eq  # move the goalpost after step up
      Write-State $st
    } elseif ($chg -lt -0.02) {
      $st.pos_pct = 5.0
      $st.baseline_equity = $eq
      Write-State $st
    }
  }
  return [double]$((Read-State).pos_pct)
}

function Decide-CadenceSec {
  param($topStats)
  # If avg vol of top set > 60 bps Ã¢â€ â€™ 8s, else 12s
  if (-not $topStats -or $topStats.Count -eq 0) { return 12 }
  $avgVol = [double](($topStats | Measure-Object -Property vol_bps -Average).Average)
  return ($(if ($avgVol -ge 60) { 8 } else { 12 }))
}

function Drawdown-Hit {
  # Use equity snapshot file to track intraday drawdown vs open-of-day
  $st = Read-State
  $utcDay = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
  if ($st.dd_day -ne $utcDay) {
    $st.dd_day = $utcDay
    $st.dd_open_eq = [double](Get-EquityUSDT)
    $st.dd_tripped = $false
    Write-State $st
    return $false
  }
  $eqNow = [double](Get-EquityUSDT)
  if ($st.dd_open_eq -gt 0) {
    $dd = ($eqNow - $st.dd_open_eq) / $st.dd_open_eq
    if ($dd -le -0.025) { $st.dd_tripped = $true; Write-State $st }
  }
  return [bool]$((Read-State).dd_tripped)
}

# Main supervisor loop
while ($true) {
  if (Test-Path ".\KILL.TRADING") { Write-Host "[ABORT] Kill-switch present." -ForegroundColor Red; break }
  if (Drawdown-Hit) { Write-Host "[PAUSE] Intraday drawdown -2.5% hit. Cooling until UTC reset." -ForegroundColor Yellow; Start-Sleep -Seconds 60; continue }

  $top = Get-TopSymbols
  if (-not $top -or $top.Count -eq 0) { Write-Host "[WAIT] No eligible symbols now." -ForegroundColor Yellow; Start-Sleep -Seconds 30; continue }

  $posPct   = Decide-PositionPct
  $eqUSDT   = [double](Get-EquityUSDT)
  if ($eqUSDT -le 0) { Write-Host "[WAIT] No USDT free." -ForegroundColor Yellow; Start-Sleep -Seconds 30; continue }

  $cadence  = Decide-CadenceSec -topStats $top
  $tp       = 0.6   # hybrid: tighten on bursts, allow tails
  $sl       = 0.5

  Write-Host "[PICK] Top $($top.Count): " -NoNewline
  $top.symbol -join ", " | Write-Host -ForegroundColor Cyan
  Write-Host ("[PARAM] equity={0:F2} USDT  pos%={1:F2}%  cadence={2}s  TP={3}% SL={4}%" -f $eqUSDT,$posPct,$cadence,$tp,$sl)

  # Launch/refresh runners for each picked symbol (one per symbol)
  foreach ($row in $top) {
    $sym = $row.symbol
    $quote = [math]::Max([math]::Round($eqUSDT * ($posPct/100.0),2), 10.0) # min $10
    $log  = Join-Path $logDir ("live_{0}_{1}.log" -f $sym, (Get-Date -f "yyyyMMdd_HHmm"))

    $args = "--symbol $sym --quote $quote --tp $tp --sl $sl --every $cadence --max-trades $MaxConcurrent"
    . .\pb-run-module-guarded.ps1 -Module "scripts.run_live_trade_safe" -Args $args -EnvFile $EnvFile -LogFile $log
  }

  # Sleep until next reselection window; runners keep working
  for ($i=0; $i -lt ($ReselectMinutes*60); $i+=10) {
    if (Test-Path ".\KILL.TRADING") { Write-Host "[ABORT] Kill-switch present." -ForegroundColor Red; break }
    if (Drawdown-Hit) { Write-Host "[PAUSE] Drawdown hit, skipping new spawns." -ForegroundColor Yellow }
    Start-Sleep -Seconds 10
  }
}
.Exception.Message)) -ForegroundColor Yellow
    return 0.0
  } finally {
    $ErrorActionPreference = $prevEAP
  }
} | Select-Object -First 1)
    if (\42 -and \42 -match 'free=([0-9\.]+)') { return [double]\[1] }
    else { return 0.0 }
  } catch {
    Write-Host "[WARN] Equity probe failed: " -ForegroundColor Yellow
    return 0.0
  } finally {
    \Continue = \
  }
} | Select-Object -First 1)
  if ($line) {
    if ($line -match 'free=([0-9\.]+)') { return [double]$Matches[1] }
  }
  return 0.0
}

function Decide-PositionPct {
  # 5% baseline, climb toward 10% when equity > baseline, back off to 5% if not
  $st = Read-State
  if (-not $st.baseline_equity) {
    $st.baseline_equity = [double](Get-EquityUSDT)
    if ($st.baseline_equity -le 0) { $st.baseline_equity = 100.0 }
    $st.pos_pct = 5.0
    Write-State $st
  }
  $eq = [double](Get-EquityUSDT)
  if ($eq -gt 0) {
    $chg = ($eq - $st.baseline_equity) / $st.baseline_equity
    if ($chg -ge 0.03) {
      $st.pos_pct = [math]::Min(10.0, $st.pos_pct + 0.5)
      $st.baseline_equity = $eq  # move the goalpost after step up
      Write-State $st
    } elseif ($chg -lt -0.02) {
      $st.pos_pct = 5.0
      $st.baseline_equity = $eq
      Write-State $st
    }
  }
  return [double]$((Read-State).pos_pct)
}

function Decide-CadenceSec {
  param($topStats)
  # If avg vol of top set > 60 bps Ã¢â€ â€™ 8s, else 12s
  if (-not $topStats -or $topStats.Count -eq 0) { return 12 }
  $avgVol = [double](($topStats | Measure-Object -Property vol_bps -Average).Average)
  return ($(if ($avgVol -ge 60) { 8 } else { 12 }))
}

function Drawdown-Hit {
  # Use equity snapshot file to track intraday drawdown vs open-of-day
  $st = Read-State
  $utcDay = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
  if ($st.dd_day -ne $utcDay) {
    $st.dd_day = $utcDay
    $st.dd_open_eq = [double](Get-EquityUSDT)
    $st.dd_tripped = $false
    Write-State $st
    return $false
  }
  $eqNow = [double](Get-EquityUSDT)
  if ($st.dd_open_eq -gt 0) {
    $dd = ($eqNow - $st.dd_open_eq) / $st.dd_open_eq
    if ($dd -le -0.025) { $st.dd_tripped = $true; Write-State $st }
  }
  return [bool]$((Read-State).dd_tripped)
}

# Main supervisor loop
while ($true) {
  if (Test-Path ".\KILL.TRADING") { Write-Host "[ABORT] Kill-switch present." -ForegroundColor Red; break }
  if (Drawdown-Hit) { Write-Host "[PAUSE] Intraday drawdown -2.5% hit. Cooling until UTC reset." -ForegroundColor Yellow; Start-Sleep -Seconds 60; continue }

  $top = Get-TopSymbols
  if (-not $top -or $top.Count -eq 0) { Write-Host "[WAIT] No eligible symbols now." -ForegroundColor Yellow; Start-Sleep -Seconds 30; continue }

  $posPct   = Decide-PositionPct
  $eqUSDT   = [double](Get-EquityUSDT)
  if ($eqUSDT -le 0) { Write-Host "[WAIT] No USDT free." -ForegroundColor Yellow; Start-Sleep -Seconds 30; continue }

  $cadence  = Decide-CadenceSec -topStats $top
  $tp       = 0.6   # hybrid: tighten on bursts, allow tails
  $sl       = 0.5

  Write-Host "[PICK] Top $($top.Count): " -NoNewline
  $top.symbol -join ", " | Write-Host -ForegroundColor Cyan
  Write-Host ("[PARAM] equity={0:F2} USDT  pos%={1:F2}%  cadence={2}s  TP={3}% SL={4}%" -f $eqUSDT,$posPct,$cadence,$tp,$sl)

  # Launch/refresh runners for each picked symbol (one per symbol)
  foreach ($row in $top) {
    $sym = $row.symbol
    $quote = [math]::Max([math]::Round($eqUSDT * ($posPct/100.0),2), 10.0) # min $10
    $log  = Join-Path $logDir ("live_{0}_{1}.log" -f $sym, (Get-Date -f "yyyyMMdd_HHmm"))

    $args = "--symbol $sym --quote $quote --tp $tp --sl $sl --every $cadence --max-trades $MaxConcurrent"
    . .\pb-run-module-guarded.ps1 -Module "scripts.run_live_trade_safe" -Args $args -EnvFile $EnvFile -LogFile $log
  }

  # Sleep until next reselection window; runners keep working
  for ($i=0; $i -lt ($ReselectMinutes*60); $i+=10) {
    if (Test-Path ".\KILL.TRADING") { Write-Host "[ABORT] Kill-switch present." -ForegroundColor Red; break }
    if (Drawdown-Hit) { Write-Host "[PAUSE] Drawdown hit, skipping new spawns." -ForegroundColor Yellow }
    Start-Sleep -Seconds 10
  }
}
