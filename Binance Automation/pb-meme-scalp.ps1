# ================== BINANCE SPOT - MEME SCALPER ==================
$BASE = $Env:BINANCE_BASE_URL; if ([string]::IsNullOrWhiteSpace($BASE)) { $BASE = 'https://api.binance.com' }
$RECV = 5000

function Get-TimestampMs { [long][DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
function Get-Signature { param([string]$Query,[string]$Secret)
  $h = New-Object System.Security.Cryptography.HMACSHA256
  $h.Key = [Text.Encoding]::UTF8.GetBytes($Secret)
  $b = [Text.Encoding]::UTF8.GetBytes($Query)
  ($h.ComputeHash($b) | % { $_.ToString('x2') }) -join '' }

function New-QueryString { param([hashtable]$Params)
  ($Params.Keys | Sort-Object | %{
    $k=[uri]::EscapeDataString($_); $v=[uri]::EscapeDataString([string]$Params[$_]); "$k=$v"
  }) -join '&' }

function Call-Public { param([string]$Path,[hashtable]$Query=@{})
  $qs = if ($Query.Count) { '?' + (New-QueryString $Query) } else { '' }
  $uri = "$BASE$Path$qs"
  Invoke-RestMethod -Method Get -Uri $uri -ErrorAction Stop
}

function Call-Signed {
  param([string]$Path,[ValidateSet('GET','POST','DELETE','PUT')][string]$Method='GET',[hashtable]$Query=@{},[hashtable]$Body=@{})
  $Query['timestamp']  = Get-TimestampMs
  $Query['recvWindow'] = $RECV
  $qs  = New-QueryString $Query
  $sig = Get-Signature -Query $qs -Secret $Env:BINANCE_API_SECRET
  $hdr = @{ 'X-MBX-APIKEY' = $Env:BINANCE_API_KEY }
  $uri = "$BASE$Path?$qs&signature=$sig"
  switch ($Method) {
    'GET'    { Invoke-RestMethod -Method Get    -Uri $uri -Headers $hdr -ErrorAction Stop }
    'DELETE' { Invoke-RestMethod -Method Delete -Uri $uri -Headers $hdr -ErrorAction Stop }
    default  {
      $bodyQs = if ($Body.Count) { New-QueryString $Body } else { '' }
      Invoke-RestMethod -Method $Method -Uri $uri -Headers $hdr -Body $bodyQs -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop
    }
  }
}

function Test-BinanceCreds {
  try { Call-Public '/api/v3/ping' | Out-Null; Call-Signed '/api/v3/account' 'GET' | Out-Null
    '✅ API reachable & credentials look valid.'; $true
  } catch { Write-Host "❌ API check failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message -ForegroundColor Yellow }
    $false }
}

function Get-FreeUSDT {
  $a = Call-Signed '/api/v3/account' 'GET'
  [double](($a.balances | ? { $_.asset -eq 'USDT' })[0].free)
}

function Get-ExchangeInfo { Call-Public '/api/v3/exchangeInfo' }
function Get-TopByVolume { param([int]$TopN=10)
  $t = Call-Public '/api/v3/ticker/24hr'
  ($t | ? { $_.symbol -like '*USDT' } | Sort-Object { [double]$_.quoteVolume } -Descending | Select -First $TopN) }

$MemeAllow = @('DOGEUSDT','SHIBUSDT','PEPEUSDT','WIFUSDT','FLOKIUSDT','BONKUSDT','POPCATUSDT','BRETTUSDT','MEWUSDT','PONKEUSDT','SATSUSDT','PEOPLEUSDT')
function Get-TopMemeSymbols { param([int]$TopN=6)
  Get-TopByVolume -TopN 300 | ? { $MemeAllow -contains $_.symbol } |
    Sort-Object { [double]$_.quoteVolume } -Descending | Select-Object -ExpandProperty symbol -First $TopN }

function Get-SymbolFilters { param([string]$Symbol)
  ($i=Get-ExchangeInfo).symbols | ? { $_.symbol -eq $Symbol } | Select-Object -ExpandProperty filters }

function Round-ToStep { param([double]$Value,[double]$Step)
  if ($Step -le 0) { return $Value }; [math]::Floor($Value / $Step) * $Step }

function Place-MarketBuy { param([string]$Symbol,[double]$QuoteUSDT)
  Call-Signed '/api/v3/order' 'POST' @{ symbol=$Symbol; side='BUY'; type='MARKET'; quoteOrderQty=[string]$QuoteUSDT; newOrderRespType='FULL' } }

function Place-LimitSellTP { param([string]$Symbol,[double]$Quantity,[double]$LimitPrice)
  $f=Get-SymbolFilters $Symbol; $lot=[double]($f|?{$_.filterType -eq 'LOT_SIZE'}).stepSize; $tick=[double]($f|?{$_.filterType -eq 'PRICE_FILTER'}).tickSize
  $qty=Round-ToStep $Quantity $lot; $px=[math]::Round((Round-ToStep $LimitPrice $tick),10)
  Call-Signed '/api/v3/order' 'POST' @{ symbol=$Symbol; side='SELL'; type='LIMIT'; timeInForce='GTC'; quantity=[string]$qty; price=[string]$px } }

function Place-StopLoss { param([string]$Symbol,[double]$Quantity,[double]$StopPrice)
  $f=Get-SymbolFilters $Symbol; $lot=[double]($f|?{$_.filterType -eq 'LOT_SIZE'}).stepSize; $tick=[double]($f|?{$_.filterType -eq 'PRICE_FILTER'}).tickSize
  $qty=Round-ToStep $Quantity $lot; $px=[math]::Round((Round-ToStep $StopPrice $tick),10)
  Call-Signed '/api/v3/order' 'POST' @{ symbol=$Symbol; side='SELL'; type='STOP_LOSS_LIMIT'; timeInForce='GTC'; quantity=[string]$qty; stopPrice=[string]$px; price=[string]$px } }

function Get-LastPrice { param([string]$Symbol)
  (Call-Public '/api/v3/ticker/price' @{symbol=$Symbol}).price -as [double] }

function Run-MemeScalp {
  param([int]$SelectTop=6,[double]$QuotePerBuy=20,[double]$TpPct=1.0,[double]$SlPct=0.8)
  if (-not (Test-BinanceCreds)) { return }
  $free = Get-FreeUSDT; if ($free -lt $QuotePerBuy) { Write-Host "Not enough USDT." -ForegroundColor Yellow; return }
  $syms = Get-TopMemeSymbols -TopN $SelectTop; if (-not $syms) { Write-Host "No MEME symbols." -ForegroundColor Yellow; return }
  $symbol=$syms[0]; $px=Get-LastPrice -Symbol $symbol
  $buy = Place-MarketBuy -Symbol $symbol -QuoteUSDT $QuotePerBuy
  $filled = ($buy.fills | Measure-Object -Property qty -Sum).Sum; if (-not $filled) { $filled=$buy.executedQty }; [double]$qty=$filled
  $tp=$px*(1+$TpPct/100); $sl=$px*(1-$SlPct/100)
  Place-LimitSellTP -Symbol $symbol -Quantity ($qty*0.5) -LimitPrice $tp | Out-Null
  Place-StopLoss   -Symbol $symbol -Quantity ($qty*0.5) -StopPrice  $sl | Out-Null
  [pscustomobject]@{ Symbol=$symbol; EntryApprox=$px; Qty=$qty; TP=[math]::Round($tp,10); SL=[math]::Round($sl,10) }
}
# ================== END ==================
