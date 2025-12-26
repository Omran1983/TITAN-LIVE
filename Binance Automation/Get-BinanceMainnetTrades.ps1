function Get-BinanceMainnetTrades {
  [CmdletBinding()]
  param(
    [datetime]$Since = (Get-Date).AddDays(-7),
    [string[]]$Symbols = @('BTCUSDT','ETHUSDT','SOLUSDT','BNBUSDT'),
    [string]$CsvOut = ".\trades_mainnet.csv",
    [string]$Account = "Main",
    [int]$RecvWindow = 5000
  )
  $ErrorActionPreference = "Stop"
  $apiKey = $Env:BINANCE_KEY
  $apiSecret = $Env:BINANCE_SECRET
  if (-not $apiKey -or -not $apiSecret) { throw "Set BINANCE_KEY and BINANCE_SECRET env vars (or load from .env)." }

  $base = "https://api.binance.com"

  function New-Signature([string]$query, [string]$secret) {
    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = [Text.Encoding]::UTF8.GetBytes($secret)
    $sig = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($query))
    ($sig | ForEach-Object { $_.ToString("x2") }) -join ""
  }

  # Ensure CSV with header
  $header = 'datetime,exchange,account,pair,side,entry_price,exit_price,qty,fees,strategy,notes'
  if (-not (Test-Path $CsvOut)) { $header | Set-Content -Encoding UTF8 $CsvOut }

  foreach ($sym in $Symbols) {
    Write-Host "Pulling myTrades for $sym since $Since ..." -ForegroundColor Cyan
    $startMs = [int64]([DateTimeOffset]$Since).ToUnixTimeMilliseconds()
    $ts      = [int64]([DateTimeOffset](Get-Date)).ToUnixTimeMilliseconds()
    $q       = "symbol=$sym&startTime=$startMs&recvWindow=$RecvWindow&timestamp=$ts"
    $sig     = New-Signature $q $apiSecret
    $url     = "$base/api/v3/myTrades?$q&signature=$sig"
    $hdr     = @{ "X-MBX-APIKEY" = $apiKey }

    $fills = Invoke-RestMethod -Method Get -Uri $url -Headers $hdr -TimeoutSec 30

    if (-not $fills -or $fills.Count -eq 0) { Write-Host "  (no fills)" -ForegroundColor DarkGray; continue }

    # FIFO: BUY lots consumed by SELLs
    $buyQ = New-Object System.Collections.Generic.List[object]
    foreach ($f in ($fills | Sort-Object time)) {
      $isBuy = [bool]$f.isBuyer
      $price = [double]$f.price
      $qty   = [double]$f.qty
      $fee   = [double]$f.commission
      $tISO  = [DateTimeOffset]::FromUnixTimeMilliseconds([int64]$f.time).UtcDateTime.ToString("s") + "Z"

      if ($isBuy) {
        $buyQ.Add([pscustomobject]@{ time=$tISO; price=$price; qty=$qty; fees=$fee }) | Out-Null
      } else {
        $remain = $qty
        while ($remain -gt 1e-12 -and $buyQ.Count -gt 0) {
          $lot = $buyQ[0]
          $use = [Math]::Min($remain, [double]$lot.qty)
          $feeAlloc = 0.0
          if ($lot.qty -gt 0) { $feeAlloc = [double]$lot.fees * ($use / [double]$lot.qty) }
          $tradeFees = $feeAlloc + $fee

          $row = '{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10}' -f `
            ($tISO), "Binance", $Account, $sym, "LONG", `
            ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F8}", $lot.price)), `
            ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F8}", $price)), `
            ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F8}", $use)), `
            ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:F8}", $tradeFees)), `
            "Spot",""

          Add-Content -Path $CsvOut -Value $row -Encoding UTF8

          $lot.qty  = [double]$lot.qty - $use
          $lot.fees = [double]$lot.fees - $feeAlloc
          if ($lot.qty -le 1e-12) { $buyQ.RemoveAt(0) }
          $remain -= $use
        }
      }
    }
  }
  Write-Host "âœ... Journal updated: $CsvOut" -ForegroundColor Green
}
