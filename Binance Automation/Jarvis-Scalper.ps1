# ----- CREATE FILE: .\Jarvis-PnL-Report.ps1 -----
$ErrorActionPreference = 'Stop'
$ScriptDir = (Get-Location).Path

function Import-DotEnv {
  param([string]$Path = (Join-Path $ScriptDir ".env"))
  if (Test-Path -LiteralPath $Path) {
    Get-Content -LiteralPath $Path -Encoding UTF8 | ForEach-Object {
      if ($_ -match "^\s*([^#=]+?)\s*=\s*(.*)$") {
        $name=$Matches[1].Trim(); $val=$Matches[2].Trim().Trim('"').Trim("'")
        Set-Item -Path ("Env:{0}" -f $name) -Value $val
      }
    }
  }
}
Import-DotEnv
if ([string]::IsNullOrWhiteSpace($env:BINANCE_API_KEY) -or [string]::IsNullOrWhiteSpace($env:BINANCE_SECRET_KEY)) { throw "Missing BINANCE_API_KEY / BINANCE_SECRET_KEY" }

function To-InvStr([double]$n,[string]$fmt="0.##########") { [string]::Format([System.Globalization.CultureInfo]::InvariantCulture,"{0:"+$fmt+"}",$n) }
function New-QueryStringSorted([hashtable]$Params) { ($Params.GetEnumerator() | Sort-Object Key | ForEach-Object { "{0}={1}" -f $_.Key,$_.Value }) -join "&" }
function Sign-Query($QueryString,$Secret){
  $h=[System.Security.Cryptography.HMACSHA256]::new([Text.Encoding]::UTF8.GetBytes($Secret))
  try { ($h.ComputeHash([Text.Encoding]::UTF8.GetBytes($QueryString))|%{ $_.ToString("x2") }) -join "" } finally { $h.Dispose() }
}
function Get-BinanceServerUnixMs {
  $t0=[DateTimeOffset]::UtcNow
  $srv=Invoke-RestMethod -Method GET -Uri "https://api.binance.com/api/v3/time" -TimeoutSec 10
  $t1=[DateTimeOffset]::UtcNow
  [int64]$srv.serverTime + [int64](($t1-$t0).TotalMilliseconds/2)
}
function Supports-SkipHttpErrorCheck { return ((Get-Command Invoke-RestMethod).Parameters.Keys -contains 'SkipHttpErrorCheck') }
function Invoke-HTTPJson {
  param([string]$Method,[string]$Uri,[hashtable]$Headers)
  if (Supports-SkipHttpErrorCheck) {
    $resp = Invoke-RestMethod -Method $Method -Uri $Uri -Headers $Headers -SkipHttpErrorCheck
    if ($resp -and $resp.PSObject.Properties['code']) { throw "HTTP ERROR -> $(ConvertTo-Json $resp -Compress)" }
    return $resp
  } else {
    try {
      $r = Invoke-WebRequest -Method $Method -Uri $Uri -Headers $Headers -UseBasicParsing
      if ($r.Content) { try { return ($r.Content | ConvertFrom-Json) } catch { return $r.Content } } else { return $null }
    } catch {
      $body = $null
      try {
        if ($_.Exception -and $_.Exception.Response) {
          $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
          $body = $sr.ReadToEnd()
        }
      } catch { }
      if (-not $body -and $_.ErrorDetails -and $_.ErrorDetails.Message) { $body = $_.ErrorDetails.Message }
      if (-not $body) { $body = $_.Exception.Message }
      throw "HTTP ERROR -> $body"
    }
  }
}
function Invoke-BinanceSigned {
  [CmdletBinding()]
  param(
    [ValidateSet("GET","POST","DELETE")]$Method,
    [string]$Base="https://api.binance.com",
    [Parameter(Mandatory)][string]$Path,
    [hashtable]$Params,
    [int]$RecvWindow=5000,
    [string]$ApiKey    = $env:BINANCE_API_KEY,
    [string]$ApiSecret = $env:BINANCE_SECRET_KEY
  )
  if (-not $Params) { $Params=@{} }
  if (-not $Params.ContainsKey("recvWindow")) { $Params.recvWindow=$RecvWindow }
  $Params.timestamp = Get-BinanceServerUnixMs
  $qs  = New-QueryStringSorted $Params
  $sig = Sign-Query $qs $ApiSecret
  $ub  = [System.UriBuilder]::new($Base)
  $p   = if ($Path.StartsWith("/")) { $Path } else { "/" + $Path }
  $ub.Path = ($ub.Path.TrimEnd("/") + $p)
  $ub.Query = "$qs&signature=$sig"
  Invoke-HTTPJson -Method $Method -Uri $ub.Uri.AbsoluteUri -Headers @{ "X-MBX-APIKEY" = $ApiKey }
}

$DaysLookback = 7
$Symbols = @('BTCUSDT','ETHUSDT','DOGEUSDT','PEPEUSDT','SHIBUSDT','WIFUSDT','FLOKIUSDT','BONKUSDT')

$sinceMs = [int64]([DateTimeOffset]::UtcNow.AddDays(-$DaysLookback).ToUnixTimeMilliseconds())

$acct = Invoke-BinanceSigned -Method GET -Path '/api/v3/account' -Params @{}
$prices = @{}
foreach ($s in $Symbols) {
  try { $p = Invoke-RestMethod -Method GET -Uri ("https://api.binance.com/api/v3/ticker/price?symbol={0}" -f $s); $prices[$s] = [double]$p.price } catch {}
}

$tradesBySym = @{}
foreach ($s in $Symbols) {
  try { $tradesBySym[$s] = Invoke-BinanceSigned -Method GET -Path '/api/v3/myTrades' -Params @{ symbol=$s; limit=100 } } catch {}
  Start-Sleep -Milliseconds 80
}

function Compute-FIFO {
  param([string]$Symbol, [object[]]$Trades, [int64]$SinceMs)
  $quote = "USDT"; $base = $Symbol -replace "USDT$",""
  $rows = @()
  foreach ($t in $Trades) {
    $timeMs=[int64]$t.time; $side=if($t.isBuyer){"BUY"}else{"SELL"}
    $qty=[double]$t.qty; $price=[double]$t.price; $quoteQty=[double]$t.quoteQty
    $fee=[double]$t.commission; $feeAsset=$t.commissionAsset
    $feeUSDT = if ($feeAsset -eq 'USDT') { $fee } else { 0.0 }
    if ($side -eq 'BUY' -and $feeAsset -eq $base) { $qty = [math]::Max(0, $qty - $fee) }
    $rows += [pscustomobject]@{ TimeMs=$timeMs; Side=$side; Qty=$qty; Price=$price; QuoteQty=$quoteQty; FeeUSDT=$feeUSDT }
  }
  $rows = $rows | Sort-Object TimeMs
  $EPS=1e-12
  $lots = New-Object System.Collections.Generic.List[object]
  $realized = 0.0
  foreach ($r in $rows) {
    if ($r.Side -eq 'BUY') {
      if ($r.Qty -gt $EPS) { $lots.Add([pscustomobject]@{ Qty=[double]$r.Qty; Cost=[double]($r.Price*$r.Qty + $r.FeeUSDT) }) }
    } else {
      $sellQty=[double]$r.Qty; $sellProceeds = ($r.Price * $sellQty) - $r.FeeUSDT
      $remaining=$sellQty; $matchedCost=0.0
      while ($remaining -gt $EPS -and $lots.Count -gt 0) {
        if ($lots[0].Qty -le $EPS) { $lots.RemoveAt(0); continue }
        $lot=$lots[0]; $take=[math]::Min($remaining,$lot.Qty); if($take -le $EPS){break}
        $cpu=$lot.Cost/$lot.Qty
        $matchedCost += $cpu*$take
        $lot.Qty=[math]::Round($lot.Qty-$take,12); $lot.Cost=[math]::Round($lot.Cost-($cpu*$take),10)
        if($lot.Qty -le $EPS){$lots.RemoveAt(0)}
        $remaining=[math]::Round($remaining-$take,12)
      }
      $realized += ($sellProceeds - $matchedCost)
    }
  }
  $posQty=0.0; $posCost=0.0
  foreach ($lot in $lots) { if ($lot.Qty -gt $EPS) { $posQty += $lot.Qty; $posCost += $lot.Cost } }

  $pre = ($rows | Where-Object { $_.TimeMs -lt $SinceMs })
  $post= ($rows | Where-Object { $_.TimeMs -ge $SinceMs })
  $seedLots = New-Object System.Collections.Generic.List[object]
  foreach ($r in $pre) {
    if ($r.Side -eq 'BUY') {
      if ($r.Qty -gt $EPS) { $seedLots.Add([pscustomobject]@{ Qty=[double]$r.Qty; Cost=[double]($r.Price*$r.Qty + $r.FeeUSDT) }) }
    } else {
      $remaining=[double]$r.Qty
      while ($remaining -gt $EPS -and $seedLots.Count -gt 0) {
        if ($seedLots[0].Qty -le $EPS) { $seedLots.RemoveAt(0); continue }
        $lot=$seedLots[0]; $take=[math]::Min($remaining,$lot.Qty); if($take -le $EPS){break}
        $cpu=$lot.Cost/$lot.Qty
        $lot.Qty=[math]::Round($lot.Qty-$take,12); $lot.Cost=[math]::Round($lot.Cost-($cpu*$take),10)
        if($lot.Qty -le $EPS){$seedLots.RemoveAt(0)}
        $remaining=[math]::Round($remaining-$take,12)
      }
    }
  }
  function Realized-On($subset,$seedLots){
    $EPS2=1e-12
    $lots2 = New-Object System.Collections.Generic.List[object]
    foreach ($sl in $seedLots) { if ($sl.Qty -gt $EPS2) { $lots2.Add([pscustomobject]@{ Qty=$sl.Qty; Cost=$sl.Cost }) } }
    $rz=0.0
    foreach ($r in $subset) {
      if ($r.Side -eq 'BUY') {
        if ($r.Qty -gt $EPS2) { $lots2.Add([pscustomobject]@{ Qty=[double]$r.Qty; Cost=[double]($r.Price*$r.Qty + $r.FeeUSDT) }) }
      } else {
        $sellQty=[double]$r.Qty; $sellProceeds = ($r.Price * $sellQty) - $r.FeeUSDT
        $remaining=$sellQty; $matchedCost=0.0
        while ($remaining -gt $EPS2 -and $lots2.Count -gt 0) {
          if ($lots2[0].Qty -le $EPS2) { $lots2.RemoveAt(0); continue }
          $lot=$lots2[0]; $take=[math]::Min($remaining,$lot.Qty); if($take -le $EPS2){break}
          $cpu=$lot.Cost/$lot.Qty
          $matchedCost += $cpu*$take
          $lot.Qty=[math]::Round($lot.Qty-$take,12); $lot.Cost=[math]::Round($lot.Cost-($cpu*$take),10)
          if($lot.Qty -le $EPS2){$lots2.RemoveAt(0)}
          $remaining=[math]::Round($remaining-$take,12)
        }
        $rz += ($sellProceeds - $matchedCost)
      }
    }
    $rz
  }
  $realizedLookback = Realized-On $post $seedLots
  [pscustomobject]@{
    Symbol=$Symbol
    RealizedPnL_USDT = [math]::Round($realizedLookback, 8)
    PosQty = [math]::Round($posQty, 8)
    PosCost_USDT = [math]::Round($posCost, 8)
  }
}

$reports = @()
foreach ($s in $Symbols) {
  $t = $tradesBySym[$s]
  if ($t -and $t.Count -gt 0) { $reports += Compute-FIFO -Symbol $s -Trades $t -SinceMs $sinceMs }
}

"`n=== REALIZED P&L (last $DaysLookback days) ==="
$realized = $reports | Select-Object Symbol, RealizedPnL_USDT | Where-Object { $_.RealizedPnL_USDT -ne $null -and -not [double]::IsNaN($_.RealizedPnL_USDT) }
$realized | Sort-Object {- $_.RealizedPnL_USDT} |
  Format-Table @{n='Symbol';e={$_.Symbol}}, @{n='RealizedPnL_USDT';e={"{0:N6}" -f $_.RealizedPnL_USDT}} -Auto
$totalReal = ($realized | Measure-Object -Property RealizedPnL_USDT -Sum).Sum
"TOTAL realized: {0:N6} USDT" -f $totalReal

"`n=== POSITIONS (unrealized) ==="
$posRows = @()
foreach ($r in $reports) {
  if ($r.PosQty -gt 0) {
    $px = if ($prices.ContainsKey($r.Symbol)) { $prices[$r.Symbol] } else { $null }
    $mkt = if ($px) { $r.PosQty * $px } else { $null }
    $unr = if ($mkt -ne $null) { $mkt - $r.PosCost_USDT } else { $null }
    $posRows += [pscustomobject]@{
      Symbol=$r.Symbol
      Qty=$r.PosQty
      Cost_USDT=$r.PosCost_USDT
      Price=$px
      Market_USDT = if ($mkt -ne $null) {[math]::Round($mkt,8)} else {$null}
      UnrealizedPnL_USDT = if ($unr -ne $null) {[math]::Round($unr,8)} else {$null}
    }
  }
}
if ($posRows.Count -gt 0) {
  $posRows | Format-Table -Auto `
    @{n='Symbol';e={$_.Symbol}},
    @{n='Qty';e={"{0:0.##########}" -f $_.Qty}},
    @{n='Cost_USDT';e={"{0:0.########}" -f $_.Cost_USDT}},
    @{n='Price';e={ if($_.Price -ne $null) { "{0:0.##########}" -f $_.Price } else { "" } }},
    @{n='Market_USDT';e={ if($_.Market_USDT -ne $null) { "{0:0.########}" -f $_.Market_USDT } else { "" } }},
    @{n='UnrealizedPnL_USDT';e={ if($_.UnrealizedPnL_USDT -ne $null) { "{0:0.########}" -f $_.UnrealizedPnL_USDT } else { "" } }}
  $totalUnreal = ($posRows | Where-Object { $_.UnrealizedPnL_USDT -ne $null } | Measure-Object -Property UnrealizedPnL_USDT -Sum).Sum
  "TOTAL unrealized: {0:N6} USDT" -f $totalUnreal
} else { "No remaining lots (flat)." }

"`n=== RECENT TRADES (latest per symbol) ==="
$recent = @()
foreach ($s in $Symbols) {
  $t = $tradesBySym[$s]
  if ($t) {
    foreach ($x in $t | Sort-Object time -Descending | Select-Object -First 20) {
      $recent += [pscustomobject]@{
        When = [DateTimeOffset]::FromUnixTimeMilliseconds([int64]$x.time).LocalDateTime
        Symbol = $s
        Side   = if ($x.isBuyer) {'BUY'} else {'SELL'}
        Qty    = [double]$x.qty
        Price  = [double]$x.price
        Quote  = [double]$x.quoteQty
        Fee    = [double]$x.commission
        FeeAsset = $x.commissionAsset
      }
    }
  }
}
if ($recent.Count -gt 0) {
  $recent | Sort-Object When -Descending |
    Format-Table -Auto `
      When, Symbol, Side,
      @{n='Qty';e={ "{0:0.##########}" -f $_.Qty }},
      @{n='Price';e={ "{0:0.##########}" -f $_.Price }},
      @{n='Quote';e={ "{0:0.######}" -f $_.Quote }},
      @{n='Fee';e={ "{0:0.##########}" -f $_.Fee }},
      FeeAsset
} else { "No trades returned." }

# CSV export
$outDir = Join-Path $ScriptDir "journal"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
($realized | Select-Object Symbol,RealizedPnL_USDT) | Export-Csv -NoTypeInformation (Join-Path $outDir "realized_pnl_${DaysLookback}d.csv")
$posRows  | Export-Csv -NoTypeInformation (Join-Path $outDir "positions.csv")
$recent   | Export-Csv -NoTypeInformation (Join-Path $outDir "recent_trades.csv")
"CSV saved to: $outDir"

