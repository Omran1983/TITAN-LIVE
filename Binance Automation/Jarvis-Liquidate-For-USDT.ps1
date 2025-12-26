<# ========================  Jarvis-Liquidate-For-USDT.ps1  ========================
Purpose: Free up USDT by selling spot holdings (excluding USDT/BNB by default).
Safety: Dry-run by default. Use -Live to place MARKET SELL orders.
USAGE:
  pwsh -NoProfile -File .\Jarvis-Liquidate-For-USDT.ps1 -TargetUSDT 25
  pwsh -NoProfile -File .\Jarvis-Liquidate-For-USDT.ps1 -TargetUSDT 25 -Live
================================================================================== #>

param(
  [decimal]$TargetUSDT = 25,
  [string[]]$ExcludeAssets = @('USDT','BNB'),
  [int]$MaxPctPerAsset = 100,
  [switch]$Live,
  [string]$LogPath = ".\journal\liquidate.log"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-Dir([string]$path){
  $dir = Split-Path -Parent $path
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
}
function Write-Log([string]$msg){
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  $line = "[$ts] $msg"
  Write-Host $line
  Ensure-Dir $LogPath
  Add-Content -Path $LogPath -Value $line
}
function New-BinanceSignature([string]$q,[string]$secret){
  $h = [System.Security.Cryptography.HMACSHA256]::new([Text.Encoding]::UTF8.GetBytes($secret))
  ($h.ComputeHash([Text.Encoding]::UTF8.GetBytes($q)) | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Invoke-BinanceSigned {
  param(
    [ValidateSet('GET','POST','DELETE')] [string]$Method = 'GET',
    [string]$Path,
    [hashtable]$Params
  )
  $api = $Env:BINANCE_API_KEY
  $sec = $Env:BINANCE_SECRET_KEY
  if ([string]::IsNullOrWhiteSpace($api) -or [string]::IsNullOrWhiteSpace($sec)) {
    throw "Missing BINANCE_API_KEY / BINANCE_SECRET_KEY environment variables."
  }
  $base = "https://api.binance.com"
  $ts = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
  if (-not $Params) { $Params = @{} }
  if (-not $Params.ContainsKey('timestamp')) { $Params.timestamp = $ts }
  if (-not $Params.ContainsKey('recvWindow')) { $Params.recvWindow = 5000 }

  $pairs = $Params.GetEnumerator() | Sort-Object Name | ForEach-Object {
    [System.Uri]::EscapeDataString($_.Key) + '=' + [System.Uri]::EscapeDataString([string]$_.Value)
  }
  $query = ($pairs -join '&')
  $sig = New-BinanceSignature $query $sec
  $uri = ('{0}{1}?{2}&signature={3}' -f $base, $Path, $query, $sig)  # no $Path? bug

  $hdr = @{ 'X-MBX-APIKEY' = $api }
  switch ($Method) {
    'GET'    { return Invoke-RestMethod -Method GET    -Uri $uri -Headers $hdr }
    'POST'   { return Invoke-RestMethod -Method POST   -Uri $uri -Headers $hdr }
    'DELETE' { return Invoke-RestMethod -Method DELETE -Uri $uri -Headers $hdr }
  }
}

function Invoke-BinancePublic {
  param([string]$Path,[hashtable]$Params)
  $base = "https://api.binance.com"
  $qs = if ($Params) {
    ($Params.GetEnumerator() | Sort-Object Name | ForEach-Object {
      [System.Uri]::EscapeDataString($_.Key) + '=' + [System.Uri]::EscapeDataString([string]$_.Value)
    }) -join '&'
  } else { '' }
  $uri = if ($qs) { ('{0}{1}?{2}' -f $base, $Path, $qs) } else { ('{0}{1}' -f $base, $Path) }
  Invoke-RestMethod -Method GET -Uri $uri
}

function Round-ToStep([decimal]$value,[decimal]$step){
  if ($step -le 0) { return $value }
  [decimal]([Math]::Floor($value / $step) * $step)
}
function Get-ExchangeInfo { Invoke-BinancePublic "/api/v3/exchangeInfo" @{} }
function Get-PriceMap {
  $ticks = Invoke-BinancePublic "/api/v3/ticker/price" @{}
  $map = @{}
  foreach($t in $ticks){ $map[$t.symbol] = [decimal]$t.price }
  return $map
}
function Get-AccountBalances {
  $acct = Invoke-BinanceSigned -Method GET -Path "/api/v3/account" -Params @{}
  $acct.balances | Where-Object {
    ([decimal]$_.free) -gt 0.00000001 -or ([decimal]$_.locked) -gt 0.00000001
  }
}
function Get-SymbolFilters([object]$sym){
  $ht = @{}
  foreach($f in $sym.filters){ $ht[$f.filterType] = $f }
  return $ht
}

try {
  Write-Log ("== Jarvis-Liquidate-For-USDT started (Live={0}, TargetUSDT={1}) ==" -f $Live.IsPresent, $TargetUSDT)

  $ex = Get-ExchangeInfo
  $priceMap = Get-PriceMap
  $balances = Get-AccountBalances

  $usdtBal = $balances | Where-Object { $_.asset -eq 'USDT' } | Select-Object -First 1
  $usdtFree = if ($usdtBal) { [decimal]$usdtBal.free } else { 0 }
  Write-Log ("USDT free (pre): {0}" -f $usdtFree)

  $remaining = [decimal]([Math]::Max($TargetUSDT - $usdtFree, 0))
  if ($remaining -le 0) {
    Write-Log "Already have >= target USDT. Nothing to do."
    return
  }

  $symMap = @{}
  foreach($s in $ex.symbols){ $symMap[$s.symbol] = $s }

  $candidates = @()
  foreach($b in $balances){
    $asset = $b.asset
    if ($ExcludeAssets -contains $asset) { continue }
    $free = [decimal]$b.free
    if ($free -le 0) { continue }

    $pair = "$asset" + "USDT"
    if (-not $symMap.ContainsKey($pair)) { continue }
    $px = $priceMap[$pair]
    if (-not $px -or $px -le 0) { continue }

    $usdVal = $free * $px
    if ($usdVal -lt 0.10) { continue }

    $candidates += [PSCustomObject]@{
      Asset = $asset
      Free  = $free
      Pair  = $pair
      Price = $px
      USDV  = [decimal]([Math]::Round($usdVal, 8))
    }
  }

  if (-not $candidates) {
    Write-Log ("No sellable assets found (excluding: {0}), or all are dust." -f ($ExcludeAssets -join ','))
    return
  }

  $candidates = $candidates | Sort-Object USDV -Descending

  Write-Log "Candidates:"
  foreach($c in $candidates){
    Write-Log ("  {0}: free={1} | px={2} | valUSDT={3}" -f $c.Asset, $c.Free, $c.Price, $c.USDV)
  }

  foreach($c in $candidates){
    if ($remaining -le 0) { break }

    $sym = $symMap[$c.Pair]
    $filters = Get-SymbolFilters $sym

    $lot = [decimal]$filters.LOT_SIZE.stepSize
    $minQty = [decimal]$filters.LOT_SIZE.minQty
    $minNotional = if ($filters.MIN_NOTIONAL) { [decimal]$filters.MIN_NOTIONAL.minNotional } else { 0 }

    # MAX SELL respecting MaxPctPerAsset and lot rounding
    $pct = [decimal]$MaxPctPerAsset
    $maxSellPre = ($c.Free * $pct) / ([decimal]100)
    $maxSell = [decimal]([Math]::Floor($maxSellPre / $lot) * $lot)
    if ($maxSell -lt $minQty) {
      Write-Log ("[SKIP] {0} — after lot rounding, maxSell({1}) < minQty({2})" -f $c.Asset,$maxSell,$minQty)
      continue
    }

    # Qty needed to cover remaining
    $needQtyRaw = $remaining / $c.Price
    $needQty = Round-ToStep $needQtyRaw $lot
    if ($needQty -lt $minQty) { $needQty = $minQty }

    $qtyToSell = [decimal]([Math]::Min($needQty, $maxSell))
    if ($qtyToSell -le 0) {
      Write-Log ("[SKIP] {0} — qtyToSell <= 0 after constraints" -f $c.Asset)
      continue
    }

    $quoteEst = $qtyToSell * $c.Price
    if ($quoteEst -lt $minNotional) {
      $minQtyNeeded = Round-ToStep ($minNotional / $c.Price) $lot
      if ($minQtyNeeded -le $maxSell -and $minQtyNeeded -gt $qtyToSell) {
        $qtyToSell = $minQtyNeeded
        $quoteEst = $qtyToSell * $c.Price
      }
    }

    if ($quoteEst -lt $minNotional) {
      Write-Log ("[SKIP] {0} — notional {1} < minNotional {2}" -f $c.Asset, [decimal]([Math]::Round($quoteEst,8)), $minNotional)
      continue
    }

    Write-Log ("PLAN: SELL {0} {1} on {2} @~{3} (approx {4} USDT)  remaining_before={5}" -f $qtyToSell, $c.Asset, $c.Pair, $c.Price, [decimal]([Math]::Round($quoteEst,4)), $remaining)

    if ($Live) {
      try {
        $order = Invoke-BinanceSigned -Method POST -Path "/api/v3/order" -Params @{
          symbol = $c.Pair
          side   = 'SELL'
          type   = 'MARKET'
          quantity = $qtyToSell
        }
        Write-Log ("EXECUTED: orderId={0} {1} SELL qty={2}" -f $order.orderId, $c.Pair, $qtyToSell)
        $remaining = [decimal]([Math]::Max($remaining - $quoteEst, 0))
        Write-Log ("UPDATED remaining_target={0}" -f [decimal]([Math]::Round($remaining,4)))
      }
      catch {
        $msg = $_.Exception.Message
        if ($_.Exception.PSObject.Properties['Response']) {
          try {
            $resp = $_.Exception.Response.GetResponseStream()
            $sr = New-Object System.IO.StreamReader($resp)
            $body = $sr.ReadToEnd()
            $msg = "$msg | BODY: $body"
          } catch {}
        }
        Write-Log ("[ERROR] Failed to sell {0}: {1}" -f $c.Asset, $msg)
      }
    } else {
      Write-Log ("DRY-RUN: would SELL {0} {1} for approx {2} USDT" -f $qtyToSell, $c.Asset, [decimal]([Math]::Round($quoteEst,4)))
      $remaining = [decimal]([Math]::Max($remaining - $quoteEst, 0))
      Write-Log ("SIM remaining_target={0}" -f [decimal]([Math]::Round($remaining,4)))
    }
  }

  if ($Live) {
    Start-Sleep -Milliseconds 500
    $balances2 = Get-AccountBalances
    $usdt2 = $balances2 | Where-Object { $_.asset -eq 'USDT' } | Select-Object -First 1
    $usdtFree2 = if ($usdt2) { [decimal]$usdt2.free } else { 0 }
    Write-Log ("USDT free (post): {0}" -f $usdtFree2)
  } else {
    Write-Log "Dry-run complete. Add -Live to execute."
  }

  Write-Log "== Jarvis-Liquidate-For-USDT finished =="
}
catch {
  $msg = $_.Exception.Message
  Write-Log ("FATAL: {0}" -f $msg)
  Write-Error $msg
  exit 1
}
