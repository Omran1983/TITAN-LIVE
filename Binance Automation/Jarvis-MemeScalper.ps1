# Jarvis-MemeScalper.ps1  — autonomous MEME scalper (uses scanner if present, else DOGE/SHIB/PEPE)
param(
  [string] $BaseUrl = $Env:BINANCE_BASE_URL,
  [double] $DailyBudgetUSDT = 44,
  [double] $PerTradeUSDT    = 8,
  [double] $StopATR = 1.5,
  [double] $TpATR   = 1.0,
  [string] $ScannerPath = ".\Jarvis-MemeScanner.ps1",
  [switch] $Live
)
$ErrorActionPreference = 'Stop'
if (-not $BaseUrl) { $BaseUrl = "https://api.binance.com" }

function Format-Decimal([double]$n){ [string]::Format([Globalization.CultureInfo]::InvariantCulture,"{0:0.##############################}",$n) }
function Sig([string]$q){ $h=New-Object System.Security.Cryptography.HMACSHA256; $h.Key=[Text.Encoding]::UTF8.GetBytes($Env:BINANCE_API_SECRET); ($h.ComputeHash([Text.Encoding]::UTF8.GetBytes($q))|%{$_.ToString('x2')}) -join '' }
function CALL([string]$m,[string]$p,[hashtable]$q=@{},[switch]$signed){
  if($signed){ $q.timestamp=[int64]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()); $q.recvWindow=5000 }
  $qs=($q.GetEnumerator()|Sort-Object Name|%{"{0}={1}" -f $_.Name,[uri]::EscapeDataString([string]$_.Value)}) -join "&"
  if($signed){ $qs = if($qs){"$qs&signature=$(Sig $qs)"}else{"signature=$(Sig '')"} }
  $u = if($qs){"$BaseUrl$p`?$qs"}else{"$BaseUrl$p"}
  $h=@{"X-MBX-APIKEY"=$Env:BINANCE_API_KEY}
  switch($m){
    'GET'    { return Invoke-RestMethod -Method GET    -Uri $u -Headers $h }
    'POST'   { return Invoke-RestMethod -Method POST   -Uri $u -Headers $h }
    'DELETE' { return Invoke-RestMethod -Method DELETE -Uri $u -Headers $h }
    default  { throw "bad method" }
  }
}
function ExInfo(){ CALL GET '/api/v3/exchangeInfo' }
function Price([string]$s){ [double](CALL GET '/api/v3/ticker/price' @{symbol=$s}).price }
function Book([string]$s){ CALL GET '/api/v3/ticker/bookTicker' @{symbol=$s} }

Write-Host ("=== JARVIS Meme Scalper (Live={0}) ===" -f [bool]$Live) -ForegroundColor Cyan

# 1) Choose symbol: use scanner if it exists and returns a table; fallback to big MEMEs
$symbol = $null
if (Test-Path -LiteralPath $ScannerPath) {
  $scanText = pwsh -NoProfile -File $ScannerPath -TopN 6
  $lines = $scanText -split "`r?`n" | Where-Object { $_ -match '^[A-Z0-9]{2,}USDT' }
  if ($lines.Count -gt 0) {
    $symbol = (($lines[0] -replace '\s{2,}',' ') -split ' ')[0]
  }
}
if (-not $symbol) { $symbol = 'DOGEUSDT' }  # fallback list could be rotated later

Write-Host ("Top pick: {0}" -f $symbol) -ForegroundColor Green

# 2) Sizing with filters
$ex = ExInfo
$si = ($ex.symbols | Where-Object { $_.symbol -eq $symbol })
if (-not $si) { throw "Symbol not found: $symbol" }
if ($si.status -ne 'TRADING') { throw "$symbol not trading" }
$lot     = $si.filters | Where-Object { $_.filterType -eq 'LOT_SIZE' }
$minQty  = [double]$lot.minQty
$step    = [double]$lot.stepSize
$minNotF = $si.filters | Where-Object { $_.filterType -eq 'MIN_NOTIONAL' }
$minNot  = if ($minNotF) { [double]$minNotF.minNotional } else { 10.0 }

$px   = Price $symbol
function RoundStep([double]$q,[double]$st){ if($st -le 0){ return [math]::Floor($q*1e8)/1e8 } $k=[math]::Floor($q/$st); [double]("{0:G17}" -f ($k*$st)) }

$qtyRaw = $PerTradeUSDT / $px
$qty    = RoundStep $qtyRaw $step
if ($qty -lt $minQty) { throw "Qty $qty < minQty $minQty. Increase PerTradeUSDT." }
if (($qty * $px) -lt $minNot) { throw "Notional $([math]::Round($qty*$px,4)) < minNotional $minNot" }

# 3) BUY
$buyQ = @{ symbol=$symbol; side='BUY'; type='MARKET'; quantity=(Format-Decimal $qty) }
$buyRes = if ($Live) { CALL POST '/api/v3/order' $buyQ -signed } else { @{ dryRun=$true; symbol=$symbol; qty=$buyQ.quantity } }
Write-Host ("BUY {0} {1} @ ~{2} [{3}]" -f (Format-Decimal $qty), $symbol, [math]::Round($px,8), ($Live ? 'EXECUTED' : 'DRYRUN')) -ForegroundColor Green

# 4) Quick ATR(1m) for TP/SL
$k = CALL GET '/api/v3/klines' @{ symbol=$symbol; interval='1m'; limit=60 }
$cl=@();$hi=@();$lo=@()
foreach($x in $k){ $cl+=[double]$x[4]; $hi+=[double]$x[2]; $lo+=[double]$x[3] }
$atr=0.0
for($i=1;$i -lt $cl.Count;$i++){
  $tr=[math]::Max($hi[$i]-$lo[$i],[math]::Max([math]::Abs($hi[$i]-$cl[$i-1]),[math]::Abs($lo[$i]-$cl[$i-1])))
  $atr += $tr
}
$atr = $atr / [math]::Max(1,($cl.Count-1))
$entry=$px; $tp=$entry + $TpATR*$atr; $sl=$entry - $StopATR*$atr
$tpStr=(Format-Decimal $tp); $slStr=(Format-Decimal $sl)

# 5) OCO if supported, else TP+SL fallback
try {
  if ($Live) {
    CALL POST '/api/v3/order/oco' @{
      symbol=$symbol; side='SELL'; quantity=(Format-Decimal $qty);
      price=$tpStr; stopPrice=$slStr; stopLimitPrice=$slStr; stopLimitTimeInForce='GTC'
    } -signed | Out-Null
  }
  Write-Host ("Placed OCO: TP={0} SL={1}" -f $tpStr,$slStr) -ForegroundColor DarkCyan
} catch {
  Write-Host "OCO not supported here; placing separate TP and SL." -ForegroundColor Yellow
  if ($Live) {
    CALL POST '/api/v3/order' @{ symbol=$symbol; side='SELL'; type='LIMIT'; timeInForce='GTC'; quantity=(Format-Decimal $qty); price=$tpStr } -signed | Out-Null
    CALL POST '/api/v3/order' @{ symbol=$symbol; side='SELL'; type='STOP_LOSS_LIMIT'; timeInForce='GTC'; quantity=(Format-Decimal $qty); price=$slStr; stopPrice=$slStr } -signed | Out-Null
  }
}

Write-Host ("Budget used (approx): {0} / {1} USDT" -f $PerTradeUSDT, $DailyBudgetUSDT) -ForegroundColor Gray
