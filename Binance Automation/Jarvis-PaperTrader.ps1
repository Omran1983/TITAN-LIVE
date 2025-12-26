param(
  [int]$SessionMinutes = 60,
  [int]$LoopMs = 1500,
  [int]$Lookback = 20,
  [int]$BreakoutBps = 2,
  [int]$TPbps = 12,
  [int]$SLbps = 18
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Load policy ---
. (Join-Path $PSScriptRoot 'Import-JarvisPolicy.ps1')
$JarvisPolicy = Import-JarvisPolicy

# --- Derived params from policy ---
$AllowedSymbols = ($JarvisPolicy.AllowedSymbols -split ',') | ForEach-Object { $_.Trim() }
$KillFileName   = $JarvisPolicy.KillSwitchFile
$DailyLossLimit = [double]$JarvisPolicy.DailyLossLimitUSDT
$MaxTradesDay   = [int]$JarvisPolicy.MaxTradesPerDay
$MaxConc        = [int]$JarvisPolicy.MaxConcurrentPositions
$MaxNotional    = [double]$JarvisPolicy.MaxNotionalPerTradeUSDT
$StreakBreak    = [int]$JarvisPolicy.StreakBreaker
$CooldownMin    = [int]$JarvisPolicy.CooldownAfterLossMinutes
$SpreadGuard    = [double]$JarvisPolicy.SpreadGuardBps
$DepthMult      = [double]$JarvisPolicy.DepthGuardMultiplier
$SlipCap        = [double]$JarvisPolicy.SlippageCapBps
$BNBMode        = ($JarvisPolicy.BNBFeeMode -eq 'ON')
$FeeRate        = if ($BNBMode) { 0.00075 } else { 0.001 }   # taker both sides in paper

# --- Paths ---
$DESK = [Environment]::GetFolderPath('Desktop')
$BASE = Join-Path $DESK 'Binance Automation'
$JOUR = Join-Path $BASE 'journal'
$LOGS = Join-Path $BASE 'logs'
$TODAY = Get-Date -Format 'yyyy-MM-dd'
$TRADES_CSV  = Join-Path $JOUR ("paper_trades_{0}.csv" -f $TODAY)
$SUM_CSV     = Join-Path $JOUR ("paper_summary_{0}.csv" -f $TODAY)

if (-not (Test-Path $TRADES_CSV)) {
  "ts_utc,symbol,side,intended_price,filled_price,qty,notional_usdt,spread_bps,slippage_bps,fee_usdt,reason,breaker_flags" |
    Set-Content -LiteralPath $TRADES_CSV -Encoding UTF8
}
if (-not (Test-Path $SUM_CSV)) {
  "date,symbol,trades,win_rate,gross_pnl_usdt,fees_usdt,slippage_cost_usdt,net_pnl_usdt" |
    Set-Content -LiteralPath $SUM_CSV -Encoding UTF8
}

# --- Utilities ---
function Get-Json([string]$url){
  for($i=0;$i -lt 6;$i++){
    try { return Invoke-RestMethod -Method GET -Uri $url -TimeoutSec 10 }
    catch { Start-Sleep -Milliseconds ([int](400 * [math]::Pow(1.8,$i))) }
  }
  return $null   # resilient: caller must handle $null
}
function NowUtc { [DateTimeOffset]::UtcNow }
function InTradingWindow([string]$win){
  if ($win -notmatch '^\s*(\d{2}):(\d{2})-(\d{2}):(\d{2})') { return $true }
  $h1=[int]$Matches[1]; $m1=[int]$Matches[2]; $h2=[int]$Matches[3]; $m2=[int]$Matches[4]
  $now = [DateTime]::UtcNow
  $start = Get-Date -Date "$($now.ToString('yyyy-MM-dd')) $h1`:$m1`:00Z" -AsUTC
  $end   = Get-Date -Date "$($now.ToString('yyyy-MM-dd')) $h2`:$m2`:00Z" -AsUTC
  return ($now -ge $start -and $now -le $end)
}
function Bps($a,$b){ if($b -eq 0){0}else{ [double]::Abs(($a-$b)/$b)*10000 } }

# Exchange info cache (tick/lot/minNotional)
$EXINFO = @{}
function Get-ExchangeInfo($symbol){
  if ($EXINFO.ContainsKey($symbol)) { return $EXINFO[$symbol] }
  $ei = Get-Json ("https://api.binance.com/api/v3/exchangeInfo?symbol={0}" -f $symbol)
  if (-not $ei) { return $null }
  $s  = $ei.symbols[0]
  if (-not $s) { return $null }
  $tick = ($s.filters | Where-Object {$_.filterType -eq 'PRICE_FILTER'}).tickSize
  $lot  = ($s.filters | Where-Object {$_.filterType -eq 'LOT_SIZE'}).stepSize
  $minN = ($s.filters | Where-Object {$_.filterType -eq 'MIN_NOTIONAL'}).minNotional
  $EXINFO[$symbol] = [pscustomobject]@{
    tickSize = [double]$tick
    stepSize = [double]$lot
    minNotional = [double]$minN
  }
  return $EXINFO[$symbol]
}
function Round-ToStep([double]$value,[double]$step){
  if ($step -le 0) { return $value }
  [math]::Floor($value / $step) * $step
}

# Depth approx checker
function HasDepth($symbol, $qty){
  $d = Get-Json ("https://api.binance.com/api/v3/depth?symbol={0}&limit=5" -f $symbol)
  if (-not $d -or -not $d.asks) { return $false }
  $asks = $d.asks | ForEach-Object { [pscustomobject]@{p=[double]$_[0]; q=[double]$_[1]} }
  $sumAsk = ($asks | Measure-Object -Property q -Sum).Sum
  return ($sumAsk -ge ($qty * $DepthMult))
}

# --- State ---
$OpenPos = $null  # {symbol, entry, qty, notional, reason}
$Wins=0; $Losses=0
$Streak=0
$CooldownUntil = [DateTime]::MinValue
$TradesToday = 0
$DailyNet = 0.0

# Rolling mids per symbol
$Mids = @{}
foreach($s in $AllowedSymbols){ $Mids[$s] = New-Object System.Collections.Queue }

# --- Start/End time ---
$startTime = (NowUtc)
$endTime   = $startTime.AddMinutes($SessionMinutes)

Write-Host "[Paper] JARVIS session started: $($startTime.UtcDateTime) → $($endTime.UtcDateTime)"

# --- Main loop ---
while ( (NowUtc) -lt $endTime ) {

  # Kill-switch
  if (Test-Path (Join-Path $PSScriptRoot $KillFileName)) {
    Write-Host "STOP.TRADING present. Halting paper session."
    break
  }

  # Session window
  if (-not (InTradingWindow $JarvisPolicy.TradingHours)) {
    Start-Sleep -Milliseconds $LoopMs
    continue
  }

  foreach($sym in $AllowedSymbols){

    if ($TradesToday -ge $MaxTradesDay) { break }
    if ([DateTime]::UtcNow -lt $CooldownUntil) { continue }

    # Market snapshot
    $bt = Get-Json ("https://api.binance.com/api/v3/ticker/bookTicker?symbol={0}" -f $sym)
    if (-not $bt) { Start-Sleep -Milliseconds 200; continue }
    $bid = [double]$bt.bidPrice; $ask=[double]$bt.askPrice
    if ($bid -le 0 -or $ask -le 0) { continue }
    $mid = ($bid + $ask) / 2.0
    $spr_bps = Bps $ask $bid

    if ($spr_bps -gt $SpreadGuard) { continue }

    # Rolling window
    $q = $Mids[$sym]
    $q.Enqueue($mid); if ($q.Count -gt $Lookback) { $q.Dequeue() }
    if ($q.Count -lt $Lookback) { continue }

    $arr = $q.ToArray()
    $prev = $arr[0..($arr.Length-2)]
    $hi = ($prev | Measure-Object -Maximum).Maximum
    $lo = ($prev | Measure-Object -Minimum).Minimum
    $brkUp = ($mid -gt $hi * (1.0 + ($BreakoutBps/10000.0)))
    $brkDn = ($mid -lt $lo * (1.0 - ($BreakoutBps/10000.0)))  # not used yet (long-only)

    if ($OpenPos -eq $null) {
      if ($brkUp -and $TradesToday -lt $MaxTradesDay) {
        $ex = Get-ExchangeInfo $sym
        if (-not $ex) { continue }
        $qty_raw = $MaxNotional / $ask
        $qty = Round-ToStep $qty_raw $ex.stepSize
        if ($qty -le 0) { continue }
        if ( ($qty * $ask) -lt $ex.minNotional ) { continue }
        if (-not (HasDepth $sym $qty)) { continue }

        $intended = $ask
        $filled   = $ask
        $slip_bps = Bps $filled $intended
        if ($slip_bps -gt $SlipCap) { $CooldownUntil = [DateTime]::UtcNow.AddMinutes($CooldownMin); continue }

        $OpenPos = [pscustomobject]@{ symbol=$sym; entry=$filled; qty=$qty; notional=($qty*$filled); reason='ENTRY' }

        # Log ENTRY immediately so CSV shows activity
        $fee_entry = $OpenPos.notional * $FeeRate
        $ts = (NowUtc).UtcDateTime.ToString('yyyy-MM-dd HH:mm:ss')
        $line = '{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11}' -f `
          $ts,$sym,'BUY',([double]::Round($intended,8)),([double]::Round($filled,8)),$qty,([double]::Round($OpenPos.notional,6)),`
          ([double]::Round($spr_bps,4)),0.0,([double]::Round($fee_entry,6)),'ENTRY',''
        Add-Content -LiteralPath $TRADES_CSV -Value $line
      }
    }
    else {
      if ($OpenPos.symbol -ne $sym) { continue }

      $tp = $OpenPos.entry * (1.0 + ($TPbps/10000.0))
      $sl = $OpenPos.entry * (1.0 - ($SLbps/10000.0))

      $exit = $null; $side = $null; $reason = $null
      if ($ask -ge $tp) { $exit = $tp; $side='SELL'; $reason='EXIT_TP' }
      elseif ($bid -le $sl) { $exit = $sl; $side='SELL'; $reason='EXIT_SL' }

      if ($exit -ne $null) {
        $intended = $exit
        $filled   = $exit
        $qty      = $OpenPos.qty
        $notional = $qty * $filled
        $fee_exit = $notional * $FeeRate
        $gross    = ($filled - $OpenPos.entry) * $qty
        $fees     = ($OpenPos.notional * $FeeRate) + $fee_exit
        $net      = $gross - $fees

        $ts = (NowUtc).UtcDateTime.ToString('yyyy-MM-dd HH:mm:ss')
        $line = '{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11}' -f `
          $ts,$sym,$side,([double]::Round($intended,8)),([double]::Round($filled,8)),$qty,([double]::Round($notional,6)),`
          ([double]::Round($spr_bps,4)),0.0,([double]::Round($fee_exit,6)),$reason,''
        Add-Content -LiteralPath $TRADES_CSV -Value $line

        # Update counters
        $TradesToday++
        if ($net -ge 0){ $Wins++; if ($Streak -lt 0) { $Streak = 1 } else { $Streak++ } }
        else { $Losses++; $Streak = -1; $CooldownUntil = [DateTime]::UtcNow.AddMinutes($CooldownMin) }
        $DailyNet += $net
        $OpenPos = $null

        # Breakers
        if ($DailyNet -le $DailyLossLimit) { Write-Host "Daily loss limit hit (paper). Ending session."; break }
        if ([Math]::Abs($Streak) -ge $StreakBreak) { Write-Host "Streak breaker tripped (paper). Cooldown."; $CooldownUntil = [DateTime]::UtcNow.AddMinutes($CooldownMin) }
      }
    }
  }

  if ($TradesToday -ge $MaxTradesDay) { Write-Host "Max trades/day reached (paper)."; break }
  Start-Sleep -Milliseconds $LoopMs
}

Write-Host "[Paper] JARVIS session ended. CSV: $TRADES_CSV"
