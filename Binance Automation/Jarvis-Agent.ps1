param(
  [string]$BaseUrl = "https://api.binance.com",
  [int]$IntervalSec = 30   # main loop cadence
)

$ErrorActionPreference = 'Stop'
$root  = if ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
$hb    = Join-Path $root "journal\heartbeat.json"
$stopf = Join-Path $root "journal\STOP_JARVIS.txt"
$log   = Join-Path $root "journal\agent.log"

function Log([string]$msg) {
  $line = "[{0}] {1}" -f (Get-Date).ToString("s"), $msg
  Add-Content -Encoding UTF8 -Path $log -Value $line
  $line
}

function Send-Tg([string]$Text) {
  if (-not $env:TG_BOT_TOKEN -or -not $env:TG_CHAT_ID) { return }
  try {
    $uri = "https://api.telegram.org/bot$($env:TG_BOT_TOKEN)/sendMessage"
    Invoke-RestMethod -Method POST -Uri $uri `
      -ContentType 'application/x-www-form-urlencoded' `
      -Body @{ chat_id=$env:TG_CHAT_ID; text=$Text } | Out-Null
  } catch { Log ("Telegram send failed: " + $_.Exception.Message) | Out-Null }
}

# lightweight health probe reused from preflight
function Get-ServerTime {
  try { Invoke-RestMethod "$BaseUrl/api/v3/time" -TimeoutSec 10 } catch { $null }
}

# Hourly heartbeat gate
$lastPingHour = -1

Log "Agent starting (PID=$PID). BaseUrl=$BaseUrl IntervalSec=$IntervalSec"
while ($true) {
  try {
    # 0) Graceful stop
    if (Test-Path $stopf) {
      Log "STOP flag detected. Exiting loop."
      break
    }

    # 1) Clock/recv health
    $svr = Get-ServerTime
    $skew = $null
    if ($svr) {
      $localMs = [int64]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
      $skew = [int64]$svr.serverTime - $localMs
    }

    # 2) TODO: plug strategy/exec ticks here (signals, router, DCA windows)
    # For now, no trading—just heartbeat. Safety-first.

    # 3) Write heartbeat
    $hbObj = [ordered]@{
      ts = (Get-Date).ToString("s")
      pid = $PID
      clock_skew_ms = $skew
      mode = "HEARTBEAT"
      note = "Replace with strategy ticks once we’re done wiring"
    }
    ($hbObj | ConvertTo-Json -Depth 6) | Set-Content -Encoding UTF8 $hb

    # 4) Hourly Telegram heartbeat
    $h = (Get-Date).Hour
    if ($h -ne $lastPingHour) {
      $lastPingHour = $h
      Send-Tg ("JARVIS heartbeat ✅ " + (Get-Date).ToString("yyyy-MM-dd HH:mm") + " | skew(ms): " + ($skew -as [string]))
    }

    Start-Sleep -Seconds $IntervalSec
  }
  catch {
    Log ("Loop error: " + $_.Exception.Message) | Out-Null
    Send-Tg ("JARVIS error ⚠️ " + $_.Exception.Message)
    Start-Sleep -Seconds ([Math]::Min($IntervalSec*2, 120))  # simple backoff
  }
}
Log "Agent stopped."
# ======================= STRATEGY ENGINE (APPEND) =======================
# Config knobs (can be overridden at start with -Aggression, -Live)
if (-not $Global:Jarvis_Aggression) { $Global:Jarvis_Aggression = 1.0 }  # 0.5..2.0 ("bravery" dial)
if (-not $Global:Jarvis_Live)       { $Global:Jarvis_Live       = $false }

# Pull policy for universe and risk
function Get-Policy {
  $cfg = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "config\policy.json"
  if (-not (Test-Path $cfg)) { throw "policy.json missing at $cfg" }
  Get-Content -Raw $cfg | ConvertFrom-Json
}

# Lightweight public endpoints
function Get-Klines([string]$symbol,[string]$interval="15m",[int]$limit=200){
  try { Invoke-RestMethod "$BaseUrl/api/v3/klines?symbol=$symbol&interval=$interval&limit=$limit" -TimeoutSec 20 } catch { $null }
}
function Get-Book([string]$symbol){ try { Invoke-RestMethod "$BaseUrl/api/v3/ticker/bookTicker?symbol=$symbol" -TimeoutSec 10 } catch { $null } }
function Get-DepthTopUSD([string]$symbol,[int]$limit=5){
  try {
    $d = Invoke-RestMethod "$BaseUrl/api/v3/depth?symbol=$symbol&limit=$limit" -TimeoutSec 10
    $sum = { param($side) $s=0.0; foreach($lvl in $side){ $s += [double]$lvl[0]*[double]$lvl[1] }; [math]::Round($s,2) }
    [math]::Min((& $sum $d.bids), (& $sum $d.asks))
  } catch { 0.0 }
}

# Indicators (pure PS)
function EMA([double[]]$x,[int]$n){
  if ($x.Count -lt $n) { return @() }
  $k = 2.0/($n+1)
  $ema = New-Object 'System.Collections.Generic.List[double]'
  $sma = ($x[0..($n-1)] | Measure-Object -Average).Average
  [void]$ema.Add([double]$sma)
  for($i=$n; $i -lt $x.Count; $i++){ $next = ($x[$i]*$k) + ($ema[$ema.Count-1]*(1-$k)); [void]$ema.Add($next) }
  return $ema.ToArray()
}
function DonchianBreak([double[]]$high,[double[]]$low,[int]$n){
  if ($high.Count -lt $n+1 -or $low.Count -lt $n+1) { return $false }
  $lookHi = ($high[(-$n-1)..(-2)] | Measure-Object -Maximum).Maximum
  $lastCloseAbove = $high[-1] -ge $lookHi
  return [bool]$lastCloseAbove
}
function RSI([double[]]$close,[int]$n=14){
  if ($close.Count -lt $n+1) { return $null }
  $g=0.0; $l=0.0
  for($i=1; $i -le $n; $i++){ $d=$close[$i]-$close[$i-1]; if($d -gt 0){$g+=$d}else{$l+=-[double]$d} }
  if ($l -eq 0) { return 100.0 }
  $rs=$g/$l; return 100.0-(100.0/(1+$rs))
}
function ROC([double[]]$close,[int]$n=10){
  if ($close.Count -lt $n+1) { return $null }
  $prev=$close[-1-$n]; $cur=$close[-1]
  if ($prev -eq 0) { return $null }
  return (($cur-$prev)/$prev)*100.0
}

# Try to use router from Jarvis-Controls if loaded; else dry-return
$haveRouter = (Get-Command New-OrderMakerFirst -ErrorAction SilentlyContinue) -ne $null

# Risk-aware size: converts a USD ticket into quantity, caps per-trade loss vs policy
function Compute-Qty([string]$symbol,[double]$price,[double]$ticketUsd,[double]$atrPct,[object]$policy){
  # apply RiskOff and Aggression
  $ticketUsd = $ticketUsd * $Global:Jarvis_Aggression * $Global:Jarvis_RiskOff
  if ($ticketUsd -lt 1) { return 0 }

  # Per-trade theoretical loss using ATR% with stop ~1.8x ATR (policy.playbooks default)
  $riskPct = [math]::Max( ($atrPct*1.8/100.0), 0.001 )
  $maxLossPct = ([double]$policy.risk.per_trade_loss_cap_pct)/100.0
  if ($riskPct -gt 0) {
    # cap: ticket notional * riskPct <= maxLossPct * ticket notional  (enforced by scaling)
    $scale = [math]::Min(1.0, $maxLossPct / $riskPct)
    $ticketUsd = $ticketUsd * $scale
  }

  # Fetch filters to snap qty
  $info = (Invoke-RestMethod "$BaseUrl/api/v3/exchangeInfo?symbol=$symbol").symbols[0]
  $lot = ($info.filters | Where-Object { $_.filterType -eq "LOT_SIZE" } | Select-Object -First 1)
  $step = if ($lot){ [double]$lot.stepSize } else { 0.0 }

  $qtyRaw = if ($price -gt 0) { $ticketUsd / $price } else { 0.0 }
  if ($step -gt 0) {
    $dec=0; if(([string]$step).Contains(".")){ $dec=([string]$step).Split('.')[1].TrimEnd('0').Length }
    $qty = [double]([decimal]::Round([decimal]([math]::Floor($qtyRaw/$step)*$step),$dec))
  } else { $qty = $qtyRaw }

  return $qty
}

# Spread/depth gates
function Pass-Micro([string]$symbol,[double]$maxSpreadBps,[double]$minDepthUsd){
  $bk = Get-Book $symbol; if (-not $bk) { return $false }
  $bid=[double]$bk.bidPrice; $ask=[double]$bk.askPrice
  $mid = ($bid+$ask)/2.0
  $spr = if ($mid -gt 0) { (($ask-$bid)/$mid)*10000 } else { 99999 }
  $depth = Get-DepthTopUSD $symbol 5
  return (@{ ok= ($spr -le $maxSpreadBps -and $depth -ge $minDepthUsd); spread_bps=[math]::Round($spr,2); depth_usd=$depth; bid=$bid; ask=$ask; mid=$mid })
}

# Single symbol decision
function Decide-And-Route([string]$symbol,[object]$policy,[switch]$Live){
  if ($policy.universe.do_not_trade -contains $symbol) {
    return @{ symbol=$symbol; status="SKIP_DNT" }
  }

  # Market regime + playbook params
  $maxSpreadBps = [int]$policy.universe.max_spread_bps
  if (-not $maxSpreadBps) { $maxSpreadBps = 12 }
  $minDepthUsd = [int]$policy.universe.min_book_depth_usd
  if (-not $minDepthUsd) { $minDepthUsd = 10000 }

  # Micro gates
  $micro = Pass-Micro $symbol $maxSpreadBps $minDepthUsd
  if (-not $micro.ok) { return @{ symbol=$symbol; status="SKIP_MICRO"; spread_bps=$micro.spread_bps; depth_usd=$micro.depth_usd } }

  # Pull 200 x 15m candles
  $k = Get-Klines $symbol "15m" 200
  if (-not $k) { return @{ symbol=$symbol; status="SKIP_KLINES" } }

  # Extract close/high/low arrays
  $close = @(); $high=@(); $low=@()
  foreach($row in $k){ $high += [double]$row[2]; $low += [double]$row[3]; $close += [double]$row[4] }

  # Indicators
  $ema20 = EMA $close 20; $ema50 = EMA $close 50
  if ($ema20.Count -eq 0 -or $ema50.Count -eq 0) { return @{ symbol=$symbol; status="SKIP_EMA" } }
  $emaBull = $ema20[-1] -gt $ema50[-1] -and $ema20[-1] -gt $ema20[-2]
  $donLong = DonchianBreak $high $low 20
  $rsi = RSI $close 14
  $roc = ROC $close 10
  $inBand = ($rsi -ge 50 -and $rsi -le 70)
  $rocUp = ($roc -gt 0)

  if (-not ($emaBull -and $donLong -and $inBand -and $rocUp)) {
    return @{ symbol=$symbol; status="NO_SIGNAL"; ema20=[math]::Round($ema20[-1],10); ema50=[math]::Round($ema50[-1],10); rsi=[math]::Round($rsi,2); roc=[math]::Round($roc,2) }
  }

  # ATR% estimate (true range proxy over last 14 bars)
  $tr = @()
  for($i=1; $i -lt $high.Count; $i++){
    $tr += [double]([Math]::Max($high[$i]-$low[$i], [Math]::Max([Math]::Abs($high[$i]-$close[$i-1]), [Math]::Abs($low[$i]-$close[$i-1]))))
  }
  $atr = (($tr[-14..-1] | Measure-Object -Average).Average)
  $atrPct = if ($close[-1] -gt 0) { ($atr/$close[-1])*100.0 } else { 0.5 }

  # Ticket sizing (Core vs Explorer). Use policy.playbooks ticket_usd_core/explorer; fall back.
  $ticketCore = 25.0
  try {
    $play = (Get-Content -Raw (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "knowledge\playbooks.yaml"))
    if ($play -match "ticket_usd_core:\s*([\d\.]+)") { $ticketCore = [double]$Matches[1] }
  } catch { }

  # Compute qty respecting risk dials
  $px = [double]$close[-1]
  $qty = Compute-Qty $symbol $px $ticketCore $atrPct $policy
  if ($qty -le 0) { return @{ symbol=$symbol; status="SIZE_ZERO" } }

  if (-not $haveRouter) {
    return @{ symbol=$symbol; status="DRY_OK"; qty=$qty; px=$px; spread_bps=$micro.spread_bps; depth_usd=$micro.depth_usd; rsi=[math]::Round($rsi,2); roc=[math]::Round($roc,2) }
  }

  # Route (DRY/LIVE)
  $o = New-OrderMakerFirst -Symbol $symbol -Side BUY -Quantity $qty -Live:$Live.IsPresent
  if ($Live) {
    return @{ symbol=$symbol; status="LIVE_SENT"; qty=$qty; px=$px; meta=$o }
  } else {
    return @{ symbol=$symbol; status="DRY_OK"; qty=$qty; px=$px; meta=$o }
  }
}

# Main tick controller: every 60s scan a subset
$scanEverySec = 60
$lastScan = [datetime]::MinValue

function Tick-Strategy {
  $p = Get-Policy
  # allow per-policy microstructure gates if present
  if (-not $p.universe.max_spread_bps)   { $p | Add-Member -NotePropertyName universe -NotePropertyValue (@{max_spread_bps=12;min_book_depth_usd=10000}) -Force }
  if (-not $p.universe.min_book_depth_usd){ $p.universe.min_book_depth_usd = 10000 }

  $syms = @()
  if ($p.universe.core_symbols){ $syms += @($p.universe.core_symbols) }
  # throttle universe size in first cut (we can widen later)
  $syms = $syms | Select-Object -Unique
  if ($syms.Count -gt 8) { $syms = $syms[0..7] }

  $LiveSwitch = if ($Global:Jarvis_Live) { "-LIVE-" } else { "-DRY-" }
  $results = @()
  foreach($s in $syms){
    $res = Decide-And-Route -symbol $s -policy $p -Live:$Global:Jarvis_Live
    $results += New-Object psobject -Property $res
  }
  # Simple telemetry to log
  $wins = ($results | ? { $_.status -in @("DRY_OK","LIVE_SENT") }).Count
  Log ("TICK $LiveSwitch agg=$($Global:Jarvis_Aggression) riskOff=$($Global:Jarvis_RiskOff) symbols=$($syms.Count) signals=$wins")
}

# Hook strategy tick into the existing loop cadence
if (-not (Get-Variable -Name JarvisAgent_OriginalLoopPatched -Scope Script -ErrorAction SilentlyContinue)) {
  Set-Variable -Name JarvisAgent_OriginalLoopPatched -Scope Script -Value $true
  # Monkey-patch: wrap the existing while(true) sleep with a timed strategy scan
  # (We can't rewrite earlier code cleanly here; we piggy-back in loop body.)
  $script:__tickWrapper = {
    $now = Get-Date
    if (($now - $lastScan).TotalSeconds -ge $scanEverySec) {
      $lastScan = $now
      try { Tick-Strategy } catch { Log ("Tick error: " + $_.Exception.Message) | Out-Null }
    }
  }
  # replace Start-Sleep calls by augmenting heartbeat loop:
  # We can't edit in place; we invoke wrapper from below before sleeping by redefining Start-Sleep proxy if needed.
  # Easiest: start a background timer that calls Tick-Strategy on cadence.
  if (-not $Global:Jarvis_TickTimer) {
    $Global:Jarvis_TickTimer = New-Object Timers.Timer
    $Global:Jarvis_TickTimer.Interval = $scanEverySec * 1000
    $Global:Jarvis_TickTimer.AutoReset = $true
    $Global:Jarvis_TickTimer.add_Elapsed({ try { Tick-Strategy } catch { Log ("Tick error(timer): " + $_.Exception.Message) | Out-Null } })
    $Global:Jarvis_TickTimer.Start()
    Log "Strategy timer started (every ${scanEverySec}s)."
  }
}
# ===================== END STRATEGY ENGINE (APPEND) =====================
