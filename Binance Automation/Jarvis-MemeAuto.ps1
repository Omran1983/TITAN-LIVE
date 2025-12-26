param(
  [double]$PerTradeUSDT   = 5,
  [int]   $MaxConcurrent  = 2,
  [double]$TakeProfitPct  = 0.012,
  [double]$StopLossPct    = 0.018,
  [double]$MinQuoteVolume = 3e7,   # $30M
  [double]$MinAbsPct      = 2.5,   # |24h %| >= 2.5
  [switch]$Live
)

$ErrorActionPreference = 'Stop'
Write-Host "MODE: MEME-ONLY v3 (fee-safe OCO)"  # fingerprint

# ===== Strict MEME/USDT allow-list =====
$memeList = @(
  'DOGEUSDT','SHIBUSDT','PEPEUSDT','FLOKIUSDT','BONKUSDT','WIFUSDT',
  'POPCATUSDT','PONKEUSDT','BRETTUSDT','SATSUSDT','PENGUUSDT'
)

# ===== Helpers =====
function Round-ToStep([double]$v,[double]$step) {
  if ($step -le 0) { return [math]::Round($v,8) }
  [math]::Round([math]::Floor($v / $step) * $step, 12)
}
function Round-Qty([double]$v,[double]$step)    {
  if ($step -le 0) { return [math]::Round($v,8) }
  [math]::Round([math]::Floor($v / $step) * $step, 8)
}
function Get-BinanceBase {
  $b = $Env:BINANCE_BASE_URL
  if ([string]::IsNullOrWhiteSpace($b)) { $b = 'https://api.binance.com' }
  if ($b -notmatch '^(?i)https?://')   { $b = 'https://' + $b }
  while ($b.EndsWith('/')) { $b = $b.Substring(0, $b.Length-1) }
  [Uri]$b
}
function Build-BinanceUri {
  param([string]$Path,[string]$QueryString)
  $base = Get-BinanceBase
  if (-not $Path.StartsWith('/')) { $Path = '/' + $Path }
  $rel  = if ([string]::IsNullOrEmpty($QueryString)) { $Path } else { $Path + '?' + $QueryString }
  [Uri]::new($base, $rel)
}
function New-BinanceSig { param([string]$Query,[string]$Secret)
  $h = New-Object System.Security.Cryptography.HMACSHA256
  $h.Key = [Text.Encoding]::UTF8.GetBytes($Secret)
  ($h.ComputeHash([Text.Encoding]::UTF8.GetBytes($Query)) | ForEach-Object { $_.ToString('x2') }) -join ''
}
function Get-ErrBody($err) {
  try { if ($err.ErrorDetails -and $err.ErrorDetails.Message) { return $err.ErrorDetails.Message } } catch {}
  try {
    $resp = $err.Exception.Response
    if ($resp -and $resp.GetResponseStream()) {
      $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
      $body = $sr.ReadToEnd(); $sr.Dispose(); return $body
    }
  } catch {}
  return ($err.Exception.Message)
}
function BZ {
  param([ValidateSet('GET','POST','DELETE')] [string]$Method,[string]$Path,[hashtable]$Query=@{},[switch]$Signed)
  $KEY    = $Env:BINANCE_API_KEY
  $SECRET = $Env:BINANCE_API_SECRET
  $pairs=@(); foreach($kv in $Query.GetEnumerator()){ $pairs += ('{0}={1}' -f $kv.Key,$kv.Value) }
  $qs = ($pairs -join '&')
  if ($Signed) {
    if ($qs) { $qs += '&' }
    $epoch = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $qs += "timestamp=$epoch"
    $sig = New-BinanceSig $qs $SECRET
    $qs += "&signature=$sig"
  }
  $uri = Build-BinanceUri $Path $qs
  $hdr = @{ 'X-MBX-APIKEY' = $KEY }
  try {
    $proxy = $Env:JARVIS_HTTP_PROXY
    if ([string]::IsNullOrWhiteSpace($proxy)) {
      Invoke-RestMethod -Method $Method -Uri $uri -Headers $hdr
    } else {
      Invoke-RestMethod -Method $Method -Uri $uri -Headers $hdr -Proxy $proxy -ProxyUseDefaultCredentials:$false
    }
  } catch {
    $body = Get-ErrBody $_
    Write-Warning ("Binance {0} {1} failed: {2}" -f $Method, $Path, $body)
    throw (New-Object System.Exception("Binance $Method $Path failed: $body"))
  }
}

# ===== Exchange Info (only memes) =====
$exInfo = BZ GET '/api/v3/exchangeInfo'
$symbolMap = @{}
foreach ($s in $exInfo.symbols) {
  if ($memeList -contains $s.symbol -and $s.status -eq 'TRADING') {
    $prc = $s.filters | Where-Object filterType -eq 'PRICE_FILTER'
    $lot = $s.filters | Where-Object filterType -eq 'LOT_SIZE'
    $not = $s.filters | Where-Object filterType -eq 'NOTIONAL'
    $symbolMap[$s.symbol] = @{
      base=$s.baseAsset
      tick=[double]$prc.tickSize
      step=[double]$lot.stepSize
      minNotional= if ($not -and $not.minNotional) { [double]$not.minNotional } else { 0 }
      minQty=[double]$lot.minQty
    }
  }
}
$valid = $memeList | Where-Object { $symbolMap.ContainsKey($_) }
if (-not $valid.Count) { throw "No valid MEME USDT symbols available (trading status?)." }

# ===== Account =====
$acct = BZ GET '/api/v3/account' @{ } -Signed
$balances = @{}; foreach ($b in $acct.balances) { $balances[$b.asset] = [double]$b.free }
$usdtFree = if ($balances.ContainsKey('USDT')) { [double]$balances['USDT'] } else { 0 }
"USDT free balance: $usdtFree"

# ===== Auto-bracket held memes (skip dust < minNotional) =====
function Ensure-Brackets {
  param([string[]]$Symbols,[double]$TpPct,[double]$SlPct)
  foreach($sym in $Symbols) {
    $meta = $symbolMap[$sym]; if (-not $meta) { continue }
    $base   = $meta.base
    $step   = $meta.step
    $tick   = $meta.tick
    $minNot = $meta.minNotional

    $held = if ($balances.ContainsKey($base)) { [double]$balances[$base] } else { 0 }
    if ($held -le 0) { continue }

    $open = @(); try { $open = BZ GET '/api/v3/openOrders' @{ symbol=$sym } -Signed } catch {}
    if ($open | Where-Object { $_.side -eq 'SELL' }) { continue }

    $ask = [double](BZ GET '/api/v3/ticker/bookTicker' @{ symbol=$sym }).askPrice
    if ($ask -le 0) { continue }

    $qty = Round-Qty $held $step
    if ($minNot -gt 0 -and ($qty * $ask) -lt $minNot) {
      Write-Warning ("Skip OCO for {0}: position {1:N4} < minNotional {2:N4}" -f $sym, ($qty*$ask), $minNot)
      continue
    }

    # fee-safe sell qty
    $sellQty = Round-Qty ($qty * 0.998) $step
    if ($sellQty -le 0 -or $sellQty -lt $meta.minQty) { continue }

    $tp   = Round-ToStep ($ask * (1+$TpPct)) $tick
    $sl   = Round-ToStep ($ask * (1-$SlPct)) $tick
    $sLim = Round-ToStep ($sl * 0.999) $tick

    try {
      BZ POST '/api/v3/order/oco' @{
        symbol=$sym; side='SELL'
        quantity=('{0:0.########}' -f $sellQty)
        price=('{0:0.########}' -f $tp)
        stopPrice=('{0:0.########}' -f $sl)
        stopLimitPrice=('{0:0.########}' -f $sLim)
        stopLimitTimeInForce='GTC'
      } -Signed | Out-Null
      Write-Host ("Attached OCO to {0} (qty={1}, TP={2}, SL={3})" -f $sym, $sellQty, $tp, $sl)
    } catch {
      Write-Warning ("OCO attach failed for {0}: {1}" -f $sym, (Get-ErrBody $_))
    }
  }
}

# ===== Candidates (MEMES ONLY) =====
$t24 = BZ GET '/api/v3/ticker/24hr'
$bySym = @{}; foreach($t in $t24){ $bySym[$t.symbol] = $t }

$candidates = foreach ($sym in $valid) {
  if ($bySym.ContainsKey($sym)) {
    $t = $bySym[$sym]
    $qv  = [double]$t.quoteVolume
    $pct = [double]$t.priceChangePercent
    if ($qv -gt $MinQuoteVolume -and [math]::Abs($pct) -ge $MinAbsPct) {
      [pscustomobject]@{
        Symbol=$sym
        QuoteVolume=$qv
        Pct=$pct
        Last=[double]$t.lastPrice
        Score=[math]::Log($qv) * ([math]::Abs($pct)+1)
      }
    }
  }
}
$candidates = $candidates | Sort-Object Score -Descending
Write-Host "=== Candidates ==="; $candidates | Select-Object -First 8 | Format-Table

# 1) Bracket held memes first (fee-safe)
Ensure-Brackets -Symbols $valid -TpPct $TakeProfitPct -SlPct $StopLossPct

# 2) Trade pass
$placed = 0
foreach ($row in ($candidates | Select-Object -First 10)) {
  if ($placed -ge $MaxConcurrent) { break }
  $sym  = $row.Symbol
  $meta = $symbolMap[$sym]; if (-not $meta) { continue }

  $base   = $meta.base
  $step   = $meta.step
  $tick   = $meta.tick
  $minNot = $meta.minNotional

  $held = if ($balances.ContainsKey($base)) { [double]$balances[$base] } else { 0 }
  if ($held -gt 0) { "Skip $sym — already holding."; continue }
  if ($usdtFree -lt $PerTradeUSDT) { break }

  # BUY
  try {
    $buy = BZ POST '/api/v3/order' @{ symbol=$sym; side='BUY'; type='MARKET'; quoteOrderQty=$PerTradeUSDT } -Signed
  } catch {
    Write-Warning ("BUY failed for {0}: {1}" -f $sym, (Get-ErrBody $_))
    continue
  }

  $avg = if ($buy.fills) {
    (($buy.fills | % { [double]$_.price * [double]$_.qty } | Measure-Object -Sum).Sum) /
    (($buy.fills | % { [double]$_.qty } | Measure-Object -Sum).Sum)
  } else {
    [double]$buy.cummulativeQuoteQty / [double]$buy.executedQty
  }
  $qty = Round-Qty ([double]$buy.executedQty) $step
  if ($qty -le 0) { Write-Warning ("Zero qty after buy for {0}." -f $sym); continue }

  # Fee-safe sell qty for OCO
  $sellQty = Round-Qty ($qty * 0.998) $step
  if ($minNot -gt 0 -and ($sellQty * $avg) -lt $minNot) {
    Write-Warning ("Post-buy {0} below minNotional: {1:N4} < {2:N4}. Skipping OCO." -f $sym, ($sellQty*$avg), $minNot)
    continue
  }
  if ($sellQty -lt $meta.minQty) {
    Write-Warning ("Post-buy {0} below minQty: {1} < {2}. Skipping OCO." -f $sym, $sellQty, $meta.minQty)
    continue
  }

  $tp   = Round-ToStep ($avg * (1+$TakeProfitPct)) $tick
  $sl   = Round-ToStep ($avg * (1-$StopLossPct)) $tick
  $sLim = Round-ToStep ($sl * 0.999) $tick

  try {
    BZ POST '/api/v3/order/oco' @{
      symbol=$sym; side='SELL'
      quantity=('{0:0.########}' -f $sellQty)
      price=('{0:0.########}' -f $tp)
      stopPrice=('{0:0.########}' -f $sl)
      stopLimitTimeInForce='GTC'
      stopLimitPrice=('{0:0.########}' -f $sLim)
    } -Signed | Out-Null
    ("Placed BUY+OCO on {0} (qty={1}, entry={2}, TP={3}, SL={4})" -f $sym, $sellQty, [math]::Round($avg,10), $tp, $sl)
    $usdtFree -= $PerTradeUSDT
    $placed++
  } catch {
    Write-Warning ("OCO failed for {0}: {1}" -f $sym, (Get-ErrBody $_))
  }
}
"=== Orders placed ==="
