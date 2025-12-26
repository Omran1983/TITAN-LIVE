<# =================  Jarvis-Addon-Reinvest.ps1  =================
Bolt-on reinvest. Separate config & clientOrderId prefix. DryRun by default.
Safe to run alongside existing scripts (no edits to your current bot).

REQUIRES env: BINANCE_API_KEY, BINANCE_SECRET_KEY
USAGE: pwsh -NoLogo -NoProfile -File .\Jarvis-Addon-Reinvest.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------- Helpers ----------
function Require-Env([string]$name){
  $v = [Environment]::GetEnvironmentVariable($name,'Process')
  if (-not $v) { $v = [Environment]::GetEnvironmentVariable($name,'User') }
  if (-not $v) { $v = [Environment]::GetEnvironmentVariable($name,'Machine') }
  if ([string]::IsNullOrWhiteSpace($v)) { throw "Missing required environment variable: $name" }
  $v.Trim('"').Trim()
}
function Has-Prop($obj, [string]$name){ $obj -and $obj.PSObject.Properties.Match($name).Count -gt 0 }

# ---------- Env ----------
$APIKEY = Require-Env 'BINANCE_API_KEY'
$SECRET = Require-Env 'BINANCE_SECRET_KEY'
$BASE   = 'https://api.binance.com'

# ---------- Crypto + HTTP ----------
function New-BinanceSignature([string]$q,[string]$s){
  $h=[System.Security.Cryptography.HMACSHA256]::new([Text.Encoding]::UTF8.GetBytes($s))
  ($h.ComputeHash([Text.Encoding]::UTF8.GetBytes($q)) | ForEach-Object { $_.ToString('x2') }) -join ''
}
function Build-Query([hashtable]$p){
  ($p.GetEnumerator() | Sort-Object Key | ForEach-Object {
    '{0}={1}' -f [uri]::EscapeDataString($_.Key), [uri]::EscapeDataString([string]$_.Value)
  }) -join '&'
}
function Invoke-BinancePublic([string]$m,[string]$p,[hashtable]$params){
  $qs  = if ($params -and $params.Count) { Build-Query $params } else { $null }
  $uri = if ($qs) { '{0}{1}?{2}' -f $BASE, $p, $qs } else { '{0}{1}' -f $BASE, $p }
  Invoke-RestMethod -Method $m -Uri $uri -TimeoutSec 30
}
function Invoke-BinanceSigned([string]$m,[string]$p,[hashtable]$params){
  if (-not $params) { $params = @{} }
  $params['timestamp'] = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
  if (-not $params.ContainsKey('recvWindow') -or -not $params['recvWindow']) { $params['recvWindow'] = 5000 }
  $q   = Build-Query $params
  $sig = New-BinanceSignature $q $SECRET
  $uri = '{0}{1}?{2}&signature={3}' -f $BASE, $p, $q, $sig
  Invoke-RestMethod -Method $m -Uri $uri -Headers @{ 'X-MBX-APIKEY' = $APIKEY } -TimeoutSec 30
}

# ---------- Config ----------
$ScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$cfgPath = Join-Path $ScriptRoot 'Jarvis.Addon.Config.json'
if (-not (Test-Path $cfgPath)) { throw "Config not found: $cfgPath" }
$Global:Cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json

# ---------- Market Data ----------
$exchangeInfoCache = @{}
function Get-ExchangeFilters([string]$sym){
  if ($exchangeInfoCache.ContainsKey($sym)) { return $exchangeInfoCache[$sym] }
  $info = Invoke-BinancePublic GET '/api/v3/exchangeInfo' @{ symbol=$sym }
  $s = $info.symbols[0]
  $lot  = $s.filters | Where-Object { $_.filterType -eq 'LOT_SIZE' }
  $prc  = $s.filters | Where-Object { $_.filterType -eq 'PRICE_FILTER' }
  $not  = $s.filters | Where-Object { $_.filterType -eq 'NOTIONAL' }
  $tick = [decimal]$prc.tickSize
  $step = [decimal]$lot.stepSize
  $minN = if ($not.minNotional) { [decimal]$not.minNotional } else { [decimal]$Global:Cfg.MinNotionalUSDDefault }
  $exchangeInfoCache[$sym] = [pscustomobject]@{ tickSize=$tick; stepSize=$step; minNotional=$minN }
  $exchangeInfoCache[$sym]
}
function Round-ToStep([decimal]$qty,[decimal]$step){
  if ($step -eq 0) { return $qty }
  [decimal]([math]::Floor($qty / $step) * $step)
}
function Round-ToTick([decimal]$px,[decimal]$tick){
  if ($tick -eq 0) { return $px }
  [decimal]([math]::Round([double]($px / $tick)) * $tick)
}
function Get-Ticker24([string]$sym){ Invoke-BinancePublic GET '/api/v3/ticker/24hr' @{ symbol=$sym } }
function Get-Klines([string]$sym,[string]$int,[int]$lim){ Invoke-BinancePublic GET '/api/v3/klines' @{ symbol=$sym; interval=$int; limit=$lim } }
function Calc-ATR14Pct([object[]]$kl){
  $rows = $kl | ForEach-Object { [pscustomobject]@{ H=[decimal]$_[2]; L=[decimal]$_[3]; C=[decimal]$_[4] } }
  if ($rows.Count -lt 15) { return 0.0 }
  $trs = New-Object System.Collections.Generic.List[decimal]
  $prev = $rows[0].C
  foreach ($r in $rows) {
    $tr = [decimal]([Math]::Max(
      [double]($r.H - $r.L),
      [Math]::Max([double]([Math]::Abs([double]($r.H - $prev))), [double]([Math]::Abs([double]($r.L - $prev))))))
    $trs.Add($tr); $prev = $r.C
  }
  $atr = ($trs | Select-Object -Last 14 | Measure-Object -Average).Average
  if ($prev -eq 0) { return 0.0 }
  [double]([decimal](100m * $atr / $prev))
}

# ---------- Account / Orders ----------
function Get-Account(){ Invoke-BinanceSigned GET '/api/v3/account' @{} }
function Get-OpenOrders(){ Invoke-BinanceSigned GET '/api/v3/openOrders' @{} }
function Get-Price([string]$sym){ [decimal](Get-Ticker24 $sym).lastPrice }
function Get-SpreadBps([string]$sym){
  $t = Get-Ticker24 $sym; $bid=[decimal]$t.bidPrice; $ask=[decimal]$t.askPrice
  if ($bid -le 0 -or $ask -le 0) { return 99999 }
  [double](10000.0 * ([double]($ask - $bid) / [double]$bid))
}
function Is-TrendingUp([string]$sym){
  $kl = Get-Klines $sym $Global:Cfg.KlineInterval 60
  $cl = $kl | ForEach-Object { [decimal]$_[4] }
  if ($cl.Count -lt 50) { return $false }
  $k = 2.0 / (50 + 1)
  $ema = [double]$cl[0]
  foreach ($c in $cl) { $ema = ($c * $k) + $ema * (1 - $k) }
  $last = [double]$cl[-1]
  return ($last -gt $ema)
}

# ---------- Sizing ----------
function Compute-OrderSize([string]$sym,[decimal]$free){
  $f = Get-ExchangeFilters $sym
  $px = Get-Price $sym
  if ($px -le 0) { throw "Zero/invalid price for $sym" }
  $base = [decimal]($free * $Global:Cfg.RiskPerEntry)
  $notional = [decimal]([Math]::Max([double]$base, [double]$f.minNotional))
  $qty = Round-ToStep ($notional / $px) $f.stepSize
  if ($qty -le 0) { throw "Computed qty <= 0 for $sym" }
  [pscustomobject]@{ qty=$qty; price=$px; notional=$qty*$px; f=$f }
}

# ---------- Orders ----------
function Place-MarketBuy([string]$sym,[decimal]$qty,[string]$cid){
  if ($Global:Cfg.DryRun) { return [pscustomobject]@{ status='DRYRUN'; symbol=$sym; qty=$qty; clientOrderId=$cid } }
  Invoke-BinanceSigned POST '/api/v3/order' @{
    symbol=$sym; side='BUY'; type='MARKET'; quantity=$qty; newClientOrderId=$cid
  }
}
function Place-OCO([string]$sym,[decimal]$tp,[decimal]$sp,[decimal]$sl,[decimal]$qty,[string]$cidBase){
  if ($Global:Cfg.DryRun) { return [pscustomobject]@{ status='DRYRUN'; symbol=$sym; tp=$tp; sp=$sp; sl=$sl; qty=$qty } }
  Invoke-BinanceSigned POST '/api/v3/order/oco' @{
    symbol=$sym; side='SELL'; quantity=$qty; price=$tp; stopPrice=$sp; stopLimitPrice=$sl; stopLimitTimeInForce='GTC';
    listClientOrderId="${cidBase}_LIST"; limitClientOrderId="${cidBase}_LIM"; stopClientOrderId="${cidBase}_STP"
  }
}

# ---------- Gates ----------
function Passes-Gates([string]$sym){
  $t = Get-Ticker24 $sym
  $volOk = ([double]$t.quoteVolume) -ge $Global:Cfg.Min24hQuoteVolUSD
  $sprOk = (Get-SpreadBps $sym) -le $Global:Cfg.MaxSpreadBps
  $atr   = Calc-ATR14Pct (Get-Klines $sym $Global:Cfg.KlineInterval $Global:Cfg.KlineLookback)
  $atrOk = $atr -ge $Global:Cfg.MinATR14Pct
  $trend = Is-TrendingUp $sym
  [pscustomobject]@{ volOk=$volOk; sprOk=$sprOk; atrOk=$atrOk; atrPct=$atr; trend=$trend }
}

# ---------- Session guards ----------
$session = [pscustomobject]@{ pnl=0.0; stopouts=0; lastEntry=[datetime]::MinValue }
$cooldown = @{}

function Check-Fences(){
  if ($session.pnl -le -[double]$Global:Cfg.DailyLossCapUSD) { throw "DailyLossCap hit: $($session.pnl)" }
  if ($session.stopouts -ge $Global:Cfg.ConsecutiveStopoutsCap) { throw "ConsecutiveStopoutsCap hit: $($session.stopouts)" }
}

# ======================== RUN ONCE ========================
Write-Host "[JR-ADDON] Start (DryRun=$($Global:Cfg.DryRun)) $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Check-Fences

# Account / slots
$acct = Get-Account
$free = [decimal](($acct.balances | Where-Object { $_.asset -eq 'USDT' }).free)
$open = Get-OpenOrders
$addonOpen = @($open | Where-Object { $_.clientOrderId -like "$($Global:Cfg.ClientOrderPrefix)*" }).Count
Write-Host ("[JR-ADDON] FreeUSDT={0} | AddonOpen={1}/{2}" -f $free,$addonOpen,$Global:Cfg.MaxConcurrent)

if ($addonOpen -ge $Global:Cfg.MaxConcurrent) { Write-Host "[JR-ADDON] Slots full. Exit."; return }
if ($free -lt [decimal]$Global:Cfg.MinNotionalUSDDefault) { Write-Host "[JR-ADDON] Free below floor. Exit."; return }

# Pick symbol
$pick = $null
foreach ($s in $Global:Cfg.Symbols) {
  if ($cooldown.ContainsKey($s) -and (Get-Date) -lt $cooldown[$s]) { continue }
  $g = Passes-Gates $s
  Write-Host ("[JR-ADDON] Gate {0}: vol={1} sprOk={2} atrOk={3}({4:N2}%) trend={5}" -f $s,$g.volOk,$g.sprOk,$g.atrOk,$g.atrPct,$g.trend)
  if ($g.volOk -and $g.sprOk -and $g.atrOk -and $g.trend) { $pick = $s; break }
}
if (-not $pick) { Write-Host "[JR-ADDON] No symbols passed. Exit."; return }

# Size
$os = Compute-OrderSize $pick $free
Write-Host ("[JR-ADDON] Sizing {0}: qty={1} price={2} notional≈{3}" -f $pick,$os.qty,$os.price,[decimal]($os.qty*$os.price))

# BUY
$cid = "{0}_{1:yyyyMMddHHmmss}_{2}" -f $Global:Cfg.ClientOrderPrefix,(Get-Date),($pick -replace 'USDT','')
$buy = Place-MarketBuy $pick $os.qty $cid
$buyStatus = if (Has-Prop $buy 'status') { $buy.status } else { 'OK' }
Write-Host ("[JR-ADDON] BUY {0}: qty={1} status={2}" -f $pick,$os.qty,$buyStatus)

# OCO
$tp = Round-ToTick ([decimal]($os.price * (1 + $Global:Cfg.TPpct))) $os.f.tickSize
$sp = Round-ToTick ([decimal]($os.price * (1 - $Global:Cfg.SLpct))) $os.f.tickSize
$sl = Round-ToTick ([decimal]($sp * [decimal]0.999)) $os.f.tickSize
if ($tp -le 0 -or $sp -le 0 -or $sl -le 0) { throw "Invalid OCO: tp=$tp sp=$sp sl=$sl" }

$oco = Place-OCO $pick $tp $sp $sl $os.qty $cid
$ocoStatus = if (Has-Prop $oco 'status') { $oco.status } else { 'OK' }
Write-Host ("[JR-ADDON] OCO {0}: tp={1} stop={2}/{3} status={4}" -f $pick,$tp,$sp,$sl,$ocoStatus)

# Cooldown & done
$cooldown[$pick] = (Get-Date).AddMinutes($Global:Cfg.PerSymbolCooldownMins)
$session.lastEntry = Get-Date
Write-Host "[JR-ADDON] Cycle complete."
