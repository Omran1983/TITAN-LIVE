param(
  [switch] $Live,                               # add -Live to actually trade
  [double] $MinNotional = 5.1,                  # ~5 USDT min + buffer
  [string] $BaseUrl = "https://api.binance.com",
  [string] $EnvFile = "F:\Jarvis\.env.mainnet"  # <-- your .env path
)
$ErrorActionPreference = 'Stop'

function Load-DotEnv([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) { throw "Env file not found: $path" }
  Get-Content -LiteralPath $path | ForEach-Object {
    $line = $_.Trim()
    if (-not $line) { return }
    if ($line.StartsWith('#')) { return }
    $idx = $line.IndexOf('=')
    if ($idx -lt 1) { return }
    $k = $line.Substring(0, $idx).Trim()
    $v = $line.Substring($idx + 1).Trim()
    # Strip surrounding quotes if present
    if (($v.StartsWith('"') -and $v.EndsWith('"')) -or ($v.StartsWith("'") -and $v.EndsWith("'"))) {
      $v = $v.Substring(1, $v.Length - 2)
    }
    if ($k) { Set-Item -Path "Env:$k" -Value $v | Out-Null }
  }
}

function Get-Signature([string]$query, [string]$secret) {
  $hmac = New-Object System.Security.Cryptography.HMACSHA256
  $hmac.Key = [Text.Encoding]::UTF8.GetBytes($secret)
  $bytes = [Text.Encoding]::UTF8.GetBytes($query)
  ($hmac.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join ''
}

function Invoke-Binance {
  param(
    [string]$Method = 'GET',
    [string]$Path,
    [hashtable]$Query = @{},
    [switch]$Signed
  )
  $key    = $Env:BINANCE_API_KEY
  $secret = $Env:BINANCE_API_SECRET
  if ([string]::IsNullOrWhiteSpace($key) -or [string]::IsNullOrWhiteSpace($secret)) {
    throw "API keys missing. Expected BINANCE_API_KEY and BINANCE_API_SECRET in env."
  }

  if ($Signed) {
    $Query.timestamp = [int64]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
    $Query.recvWindow = 5000
  }

  $qs = ($Query.GetEnumerator() | Sort-Object -Property Name | ForEach-Object { "{0}={1}" -f $_.Name, [uri]::EscapeDataString([string]$_.Value) }) -join "&"
  if ($Signed) {
    $sig = Get-Signature $qs $secret
    $qs = if ($qs) { "$qs&signature=$sig" } else { "signature=$sig" }
  }

  $uri = if ($qs) { "$BaseUrl$Path`?$qs" } else { "$BaseUrl$Path" }
  $headers = @{ "X-MBX-APIKEY" = $key }

  try {
    switch ($Method) {
      'GET'    { return Invoke-RestMethod -Method GET    -Uri $uri -Headers $headers }
      'POST'   { return Invoke-RestMethod -Method POST   -Uri $uri -Headers $headers }
      'DELETE' { return Invoke-RestMethod -Method DELETE -Uri $uri -Headers $headers }
      default  { throw "Unsupported method $Method" }
    }
  } catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Yellow }
    throw
  }
}

function Get-ExchangeInfo {
  if (-not $script:EXINFO) { $script:EXINFO = Invoke-Binance -Path '/api/v3/exchangeInfo' }
  return $script:EXINFO
}

function Get-SymbolInfo([string]$symbol) {
  $ex = Get-ExchangeInfo
  return ($ex.symbols | Where-Object { $_.symbol -eq $symbol })
}

function Round-ToStep([double]$qty, [double]$step) {
  if ($step -le 0) { return [math]::Floor($qty * 1e8)/1e8 }
  $k = [math]::Floor($qty / $step)
  return [double]("{0:G17}" -f ($k * $step))
}

function Get-Price([string]$symbol) {
  $d = Invoke-Binance -Path '/api/v3/ticker/price' -Query @{ symbol = $symbol }
  return [double]$d.price
}

function Place-MarketSell([string]$symbol, [double]$qty) {
  $q = @{
    symbol   = $symbol
    side     = 'SELL'
    type     = 'MARKET'
    quantity = "{0:G17}" -f $qty
  }
  if ($Live) {
    return Invoke-Binance -Method 'POST' -Path '/api/v3/order' -Query $q -Signed
  } else {
    return @{ dryRun = $true; symbol = $symbol; quantity = $q.quantity }
  }
}

function Get-Balances() {
  $acc = Invoke-Binance -Path '/api/v3/account' -Signed
  return $acc.balances | Where-Object { [double]$_.free -gt 0 -or [double]$_.locked -gt 0 }
}

# === bootstrap ===
Load-DotEnv -path $EnvFile
Write-Host ("=== Convert-AllToUSDT (DryRun={0}) ===" -f ([bool](-not $Live))) -ForegroundColor Cyan

$balances = Get-Balances
$targets  = $balances | Where-Object { $_.asset -ne 'USDT' -and [double]$_.free -gt 0.0 }
if (-not $targets) {
  Write-Host "No convertible assets found (already USDT or zero balances)." -ForegroundColor Yellow
  return
}

$priceCache = @{}
$orders = @()

foreach ($b in $targets) {
  $asset = $b.asset
  $free  = [double]$b.free

  # Keep BNB for fee discounts? Uncomment next line to keep:
  # if ($asset -eq 'BNB') { continue }

  $preferred = "$asset" + 'USDT'
  if ($asset -eq 'USDC') { $preferred = 'USDCUSDT' }
  if ($asset -eq 'BUSD') { $preferred = 'BUSDUSDT' }

  $symInfo = Get-SymbolInfo $preferred
  if (-not $symInfo) { Write-Host ("No direct USDT pair for {0} (e.g., {1}). Skipping." -f $asset, $preferred) -ForegroundColor DarkYellow; continue }
  if ($symInfo.status -ne 'TRADING') { Write-Host ("{0} not trading. Skipping." -f $preferred) -ForegroundColor DarkYellow; continue }

  $lot     = ($symInfo.filters | Where-Object { $_.filterType -eq 'LOT_SIZE' })
  $minQty  = [double]$lot.minQty
  $step    = [double]$lot.stepSize

  $notionalF = ($symInfo.filters | Where-Object { $_.filterType -eq 'MIN_NOTIONAL' })
  $minNot    = if ($notionalF) { [double]$notionalF.minNotional } else { 0.0 }

  if (-not $priceCache.ContainsKey($preferred)) { $priceCache[$preferred] = Get-Price $preferred }
  $px = $priceCache[$preferred]

  $qtyStep = Round-ToStep $free $step
  if ($qtyStep -lt $minQty) { Write-Host ("{0} qty {1} < minQty {2} — skipping." -f $asset, $qtyStep, $minQty) -ForegroundColor DarkYellow; continue }

  $notional  = $qtyStep * $px
  $threshold = [math]::Max($MinNotional, $minNot)
  if ($notional -lt $threshold) { Write-Host ("{0} notional ~{1} < minNotional {2} — skipping (dust)." -f $asset, [math]::Round($notional,4), $threshold) -ForegroundColor DarkYellow; continue }

  try {
    $res = Place-MarketSell -symbol $preferred -qty $qtyStep
    $orders += [pscustomobject]@{
      asset    = $asset
      symbol   = $preferred
      qty      = $qtyStep
      price    = $px
      notional = [math]::Round($qtyStep * $px, 6)
      live     = [bool]$Live
      result   = $res
    }
    $mode = if ($Live) { "EXECUTED" } else { "DRYRUN" }
    Write-Host ("{0}: SELL {1} {2} -> {3} @ ~{4} (≈ {5} USDT)" -f $mode, $qtyStep, $asset, $preferred, $px, [math]::Round($qtyStep*$px,2)) -ForegroundColor Green
  } catch {
    Write-Host ("Order failed for {0}: {1}" -f $preferred, $_.Exception.Message) -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Yellow }
  }
}

try {
  $final = Get-Balances
  $usdt  = $final | Where-Object { $_.asset -eq 'USDT' }
  if ($usdt) {
    Write-Host ("`nUSDT Balance (free/locked): {0} / {1}" -f ([double]$usdt.free), ([double]$usdt.locked)) -ForegroundColor Cyan
  }
} catch {}

"`n=== Summary ==="
$orders | Sort-Object -Property notional -Descending | Format-Table asset, symbol, qty, price, notional, live
