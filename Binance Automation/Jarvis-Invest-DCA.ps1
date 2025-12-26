param(
  [string]$BaseUrl = "https://api.binance.com",
  [switch]$DryRun
)

$root   = if ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
$cfgDir = Join-Path $root "config"
$logDir = Join-Path $root "journal"
$null = New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logCsv = Join-Path $logDir ("invest_" + (Get-Date -Format "yyyyMMdd") + ".csv")

function Read-Policy {
  $p = Get-Content -Raw (Join-Path $cfgDir "policy.json") | ConvertFrom-Json
  if (-not $p.invest_sleeve.enabled) { throw "Invest Sleeve disabled in policy.json" }
  if (-not $p.invest_sleeve.never_sell) { throw "Invest Sleeve must be never_sell=true" }
  return $p
}

function HmacSHA256Hex([string]$msg, [string]$secret) {
  $h = New-Object System.Security.Cryptography.HMACSHA256
  $h.Key = [Text.Encoding]::UTF8.GetBytes($secret)
  ($h.ComputeHash([Text.Encoding]::UTF8.GetBytes($msg)) | ForEach-Object { $_.ToString("x2") }) -join ''
}

function Invoke-BinancePrivate {
  param([ValidateSet("GET","POST","DELETE","PUT")]$Method,[string]$Endpoint,[hashtable]$Query=@{})
  if (-not $env:BINANCE_API_KEY -or -not $env:BINANCE_API_SECRET) { throw "API env vars missing." }
  $Query.timestamp = [int64]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
  $Query.recvWindow = 2000
  $q = ($Query.Keys | Sort-Object | ForEach-Object { "$_=$([uri]::EscapeDataString([string]$Query[$_]))" }) -join "&"
  $sig = HmacSHA256Hex $q $env:BINANCE_API_SECRET
  $url = "$BaseUrl$Endpoint?$q&signature=$sig"
  Invoke-RestMethod -Method $Method -Uri $url -Headers @{ "X-MBX-APIKEY" = $env:BINANCE_API_KEY } -TimeoutSec 20
}

function Get-Price([string]$symbol)   { (Invoke-RestMethod "$BaseUrl/api/v3/ticker/price?symbol=$symbol").price }
function Get-SymbolInfo([string]$sym) { (Invoke-RestMethod "$BaseUrl/api/v3/exchangeInfo?symbol=$sym").symbols[0] }

function SnapQty([double]$qty,[double]$step){
  if ($step -le 0) { return $qty }
  $d = [math]::Floor($qty/$step)*$step
  $dec=0; if(([string]$step).Contains(".")){ $dec=([string]$step).Split('.')[1].TrimEnd('0').Length }
  return [decimal]::Round([decimal]$d,$dec)
}
function Ensure-Row($path){ if(-not(Test-Path $path)){ "ts,symbol,side,usdt,price,qty,orderId,dry_run" | Set-Content -Encoding UTF8 $path } }

# 1) Load policy
$p = Read-Policy
$alloc = $p.invest_sleeve.targets
$per   = [double]$p.invest_sleeve.per_cycle_usdt

Ensure-Row $logCsv
$results = @()

# 2) Loop targets and buy per allocation (DRY by default)
foreach ($kv in $alloc.PSObject.Properties) {
  $sym = $kv.Name
  $w   = [double]$kv.Value
  $usdt = [math]::Round($per * $w, 2)
  if ($usdt -le 0) { continue }

  # Fetch price and exchange filters
  $px = [double](Get-Price $sym)
  $info = Get-SymbolInfo $sym
  if (-not $info) {
    $results += [pscustomobject]@{ symbol=$sym; status="SKIP_NO_INFO"; usdt=$usdt; price=$px; qty=0; orderId=$null; dry=$DryRun.IsPresent }
    continue
  }

  $lotFilter = ($info.filters | Where-Object { $_.filterType -eq "LOT_SIZE" }) | Select-Object -First 1
  $notionalFilter = ($info.filters | Where-Object { $_.filterType -in @("MIN_NOTIONAL","NOTIONAL") }) | Select-Object -First 1
  $step = if ($lotFilter) { [double]$lotFilter.stepSize } else { 0 }
  $minNotional = if ($notionalFilter) { [double]$notionalFilter.minNotional } else { 0 }

  # Compute qty from notional and snap to step
  $qtyRaw = if ($px -gt 0) { $usdt / $px } else { 0 }
  $qty = [double](SnapQty $qtyRaw $step)

  # Check minNotional (if provided)
  $estNotional = $qty * $px
  if ($minNotional -gt 0 -and $estNotional -lt $minNotional) {
    $results += [pscustomobject]@{ symbol=$sym; status="SKIP_MIN_NOTIONAL"; usdt=$usdt; price=$px; qty=$qty; orderId=$null; dry=$DryRun.IsPresent }
    continue
  }

  if ($DryRun) {
    $results += [pscustomobject]@{ symbol=$sym; status="DRY_OK"; usdt=$usdt; price=$px; qty=$qty; orderId=$null; dry=$true }
  } else {
    # Spend USDT directly with quoteOrderQty
    $o = Invoke-BinancePrivate -Method POST -Endpoint "/api/v3/order" -Query @{
      symbol=$sym; side="BUY"; type="MARKET"; quoteOrderQty=("{0:0.##}" -f $usdt)
    }
    $oid = $o.orderId
    $results += [pscustomobject]@{ symbol=$sym; status="LIVE_OK"; usdt=$usdt; price=$px; qty=$qty; orderId=$oid; dry=$false }
  }
}

# 3) Log CSV (PS 5.1 safe — no ternary)
foreach ($r in $results) {
  $oid = ""
  if ($r.orderId) { $oid = $r.orderId }
  $line = "{0},{1},{2},{3},{4},{5},{6},{7}" -f (Get-Date).ToString("s"), $r.symbol, "BUY", $r.usdt, $r.price, $r.qty, $oid, $r.dry
  Add-Content -Encoding UTF8 -Path $logCsv -Value $line
}

# 4) Echo summary
$results | Format-Table -AutoSize
Write-Host "Log -> $logCsv"
# ================== Telegram Alert (optional) ==================
function Send-Tg([string]$Text) {
  if (-not $env:TG_BOT_TOKEN -or -not $env:TG_CHAT_ID) { return }
  try {
    $uri = "https://api.telegram.org/bot$($env:TG_BOT_TOKEN)/sendMessage"
    Invoke-RestMethod -Method POST -Uri $uri `
      -ContentType 'application/x-www-form-urlencoded' `
      -Body @{ chat_id=$env:TG_CHAT_ID; text=$Text } | Out-Null
  } catch { Write-Warning ("Telegram send failed: " + $_.Exception.Message) }
}

# Build concise run summary and send
$cnt    = $results.Count
$okc    = ($results | Where-Object { $_.status -like '*OK' }).Count
$skips  = $cnt - $okc
$sumUsd = [math]::Round( ((($results | ForEach-Object { $_.usdt }) | Measure-Object -Sum).Sum), 2 )
$syms   = ($results | ForEach-Object { $_.symbol } | Select-Object -Unique) -join ', '
$mode   = if ($DryRun) { 'DRY' } else { 'LIVE' }

$txt = @"
JARVIS · Invest Sleeve DCA
Mode: $mode
Symbols: $syms
OK: $okc / $cnt | Skips: $skips
Planned USDT: $sumUsd
Log: $logCsv
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm')
"@

Send-Tg $txt
# ================================================================
