# --------------------------- Jarvis-Controls.ps1 ---------------------------
# Ops controls: PanicStop, Resume, Set-RiskOff, and Maker-first router (DRY by default)
# Requires: $Env:BINANCE_API_KEY and $Env:BINANCE_API_SECRET

# Defaults (override in your session if needed)
if (-not $Global:Jarvis_BaseUrl) { $Global:Jarvis_BaseUrl = "https://api.binance.com" }
if (-not $Global:Jarvis_RecvWin) { $Global:Jarvis_RecvWin = 2000 }

function New-Signature([string]$Query,[string]$Secret) {
  $h = New-Object System.Security.Cryptography.HMACSHA256
  $h.Key = [Text.Encoding]::UTF8.GetBytes($Secret)
  ($h.ComputeHash([Text.Encoding]::UTF8.GetBytes($Query)) | ForEach-Object { $_.ToString("x2") }) -join ''
}

function Invoke-BinancePrivate {
  param(
    [Parameter(Mandatory)][ValidateSet("GET","POST","DELETE","PUT")] [string]$Method,
    [Parameter(Mandatory)][string]$Endpoint,
    [hashtable]$Query = @{}
  )
  if (-not $env:BINANCE_API_KEY -or -not $env:BINANCE_API_SECRET) { throw "API env vars missing." }
  $Query.timestamp = [int64]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
  $Query.recvWindow = $Global:Jarvis_RecvWin
  # URL-encode values to be safe
  $q = ($Query.Keys | Sort-Object | ForEach-Object { "$_=$([uri]::EscapeDataString([string]$Query[$_]))" }) -join "&"
  $sig = New-Signature $q $env:BINANCE_API_SECRET
  $url = "$($Global:Jarvis_BaseUrl)$Endpoint?$q&signature=$sig"
  Invoke-RestMethod -Method $Method -Uri $url -Headers @{ "X-MBX-APIKEY" = $env:BINANCE_API_KEY } -TimeoutSec 15
}

function Get-OpenOrders([string]$Symbol = $null) {
  $q=@{}; if ($Symbol) { $q.symbol=$Symbol }
  Invoke-BinancePrivate -Method GET -Endpoint "/api/v3/openOrders" -Query $q
}

function Cancel-AllOrders([string]$Symbol) {
  try {
    Invoke-BinancePrivate -Method DELETE -Endpoint "/api/v3/openOrders" -Query @{ symbol=$Symbol }
    Write-Host "Cancelled all orders on $Symbol"
  } catch { Write-Warning "Cancel failed on $($Symbol): $($_.Exception.Message)" }
}

function Get-Account([switch]$AllBalances) {
  $acc = Invoke-BinancePrivate -Method GET -Endpoint "/api/v3/account"
  if ($AllBalances) { return $acc } else {
    $acc.balances | Where-Object { [double]$_.free -gt 0 -or [double]$_.locked -gt 0 }
  }
}

function Market-SellAllToUSDT([string[]]$Symbols) {
  foreach ($sym in $Symbols) {
    try {
      $ex  = Invoke-RestMethod "$($Global:Jarvis_BaseUrl)/api/v3/exchangeInfo?symbol=$sym"
      $lot = ($ex.symbols.filters | Where-Object filterType -eq "LOT_SIZE")[0]
      $step = [double]$lot.stepSize

      $base = $sym -replace "USDT",""
      $acc = Get-Account -AllBalances
      $bal = ($acc.balances | Where-Object asset -eq $base)
      $qty = [double]$bal.free
      if ($qty -le 0) { continue }

      function Snap([double]$x,[double]$s){
        if ($s -le 0) { return $x }
        $d = [math]::Floor($x/$s)*$s
        $dec = 0
        if ($s -gt 0 -and ([string]$s).Contains(".")) {
          $dec = ([string]$s).Split('.')[1].TrimEnd('0').Length
        }
        return [decimal]::Round([decimal]$d,$dec)
      }
      $qSnap = [double](Snap $qty $step)
      if ($qSnap -le 0) { continue }

      $o = Invoke-BinancePrivate -Method POST -Endpoint "/api/v3/order" -Query @{
        symbol=$sym; side="SELL"; type="MARKET"; quantity=$qSnap
      }
      Write-Host "Sold $qSnap $base -> USDT (orderId=$($o.orderId))"
    } catch { Write-Warning "SellAll $sym failed: $($_.Exception.Message)" }
  }
}

function PanicStop {
  param([string[]]$SymbolsToLiquidate = @())
  Write-Host "PANIC STOP: Cancelling open orders..." -ForegroundColor Red
  try {
    $opens = Get-OpenOrders
    if ($opens) {
      $bySym = $opens | Group-Object symbol
      foreach ($g in $bySym) { Cancel-AllOrders $g.Name }
    }
  } catch { Write-Warning "OpenOrders fetch failed: $($_.Exception.Message)" }

  if ($SymbolsToLiquidate.Count -gt 0) {
    Write-Host "PANIC STOP: Market-selling positions into USDT..." -ForegroundColor Red
    Market-SellAllToUSDT -Symbols $SymbolsToLiquidate
  }
  Write-Host "PANIC STOP complete."
}

# Risk scaler
if (-not $Global:Jarvis_RiskOff) { $Global:Jarvis_RiskOff = 1.0 }
function Set-RiskOff([double]$Scale) {
  if ($Scale -le 0 -or $Scale -gt 1.0) { throw "Scale must be in (0,1]." }
  $Global:Jarvis_RiskOff = $Scale
  Write-Host "RiskOff set to $Scale (ticket sizes will scale down)." -ForegroundColor Yellow
}
function Resume {
  $Global:Jarvis_RiskOff = 1.0
  Write-Host "Trading resumed; RiskOff=1.0"
}

# Maker-first router (DRY by default)
function New-OrderMakerFirst {
  param(
    [Parameter(Mandatory)][string]$Symbol,
    [Parameter(Mandatory)][ValidateSet("BUY","SELL")] [string]$Side,
    [Parameter(Mandatory)][double]$Quantity,
    [double]$LimitPrice = 0.0,
    [int]$SlippageBpsCap = 12,
    [switch]$Live
  )
  $bt = Invoke-RestMethod "$($Global:Jarvis_BaseUrl)/api/v3/ticker/bookTicker?symbol=$Symbol"
  $bid = [double]$bt.bidPrice; $ask = [double]$bt.askPrice
  $mid = ($bid + $ask)/2.0

  if (-not $Live) {
    return [PSCustomObject]@{
      mode="DRY"; symbol=$Symbol; side=$Side; qty=$Quantity; mid=$mid; bid=$bid; ask=$ask
      action="LIMIT_MAKER at favorable tick; fallback IOC if not filled in time-window"
    }
  }

  # LIVE path
  $price = if ($Side -eq "BUY") { [math]::Min($mid, $ask) } else { [math]::Max($mid, $bid) }
  try {
    $o = Invoke-BinancePrivate -Method POST -Endpoint "/api/v3/order" -Query @{
      symbol=$Symbol; side=$Side; type="LIMIT_MAKER"; quantity=$Quantity; price=("{0:0.########}" -f $price)
    }
    return $o
  } catch {
    $last = Invoke-RestMethod "$($Global:Jarvis_BaseUrl)/api/v3/ticker/price?symbol=$Symbol"
    $px   = [double]$last.price
    $slipBps = if ($Side -eq "BUY") { (($px - $ask)/$mid)*10000 } else { (($bid - $px)/$mid)*10000 }
    if ([math]::Abs($slipBps) -gt $SlippageBpsCap) { throw "Slippage cap exceeded ($([math]::Round($slipBps,2)) bps > $SlippageBpsCap bps)" }
    return (Invoke-BinancePrivate -Method POST -Endpoint "/api/v3/order" -Query @{
      symbol=$Symbol; side=$Side; type="MARKET"; quantity=$Quantity
    })
  }
}
# ------------------------- end Jarvis-Controls.ps1 --------------------------

