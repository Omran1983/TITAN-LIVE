# ===== MEME MODULE (namespaced, safe) =====
$script:BZ_BASE = $Env:BINANCE_BASE_URL; if ([string]::IsNullOrWhiteSpace($script:BZ_BASE)) { $script:BZ_BASE = 'https://api.binance.com' }
$script:BZ_RECV = 5000

function BZ-TimeMs { [long][DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
function BZ-QS { param([hashtable]$H) ($H.Keys | Sort-Object | % { "$_=$([uri]::EscapeDataString([string]$H[$_]))" }) -join '&' }
function BZ-Sign { param([string]$Q) $h=[System.Security.Cryptography.HMACSHA256]::new([Text.Encoding]::UTF8.GetBytes($Env:BINANCE_API_SECRET)); 
  ($h.ComputeHash([Text.Encoding]::UTF8.GetBytes($Q)) | % { $_.ToString('x2') }) -join '' }

function BZ-Public { param([string]$Path,[hashtable]$Query=@{})
  $qs = if($Query.Count){'?'+(BZ-QS $Query)} else {''}
  $uri = "$script:BZ_BASE$Path$qs"
  Invoke-RestMethod -Method Get -Uri $uri -ErrorAction Stop
}

function BZ-Signed { param([string]$Path,[ValidateSet('GET','POST','DELETE','PUT')][string]$Method='GET',[hashtable]$Query=@{},[hashtable]$Body=@{})
  $Query['timestamp']=BZ-TimeMs; $Query['recvWindow']=$script:BZ_RECV
  $qs  = BZ-QS $Query
  $sig = BZ-Sign $qs
  $hdr = @{ 'X-MBX-APIKEY' = $Env:BINANCE_API_KEY }
  $uri = "$script:BZ_BASE$Path?$qs&signature=$sig"
  switch ($Method) {
    'GET'    { Invoke-RestMethod -Method Get    -Uri $uri -Headers $hdr -ErrorAction Stop }
    'DELETE' { Invoke-RestMethod -Method Delete -Uri $uri -Headers $hdr -ErrorAction Stop }
    default  { $bodyQs = if($Body.Count){ BZ-QS $Body } else { '' }
               Invoke-RestMethod -Method $Method -Uri $uri -Headers $hdr -Body $bodyQs -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop }
  }
}

function BZ-TestCreds {
  try { BZ-Public '/api/v3/ping' | Out-Null; BZ-Signed '/api/v3/account' 'GET' | Out-Null; '✅ API reachable & credentials look valid.'; $true }
  catch { Write-Host "❌ API check failed:" -ForegroundColor Red
         Write-Host $_.Exception.Message -ForegroundColor Yellow
         if ($_.ErrorDetails.Message){ Write-Host $_.ErrorDetails.Message -ForegroundColor Yellow }
         $false }
}

function BZ-ExchangeInfo { BZ-Public '/api/v3/exchangeInfo' }
function BZ-TopByVol { param([int]$N=300)
  BZ-Public '/api/v3/ticker/24hr' | ? { $_.symbol -like '*USDT' } |
    Sort-Object { [double]$_.quoteVolume } -Descending | Select -First $N }

$script:BZ_MEME = @('DOGEUSDT','SHIBUSDT','PEPEUSDT','WIFUSDT','FLOKIUSDT','BONKUSDT','POPCATUSDT','BRETTUSDT','MEWUSDT','PONKEUSDT','SATSUSDT','PEOPLEUSDT')
function BZ-TopMeme { param([int]$N=6)
  BZ-TopByVol -N 300 | ? { $script:BZ_MEME -contains $_.symbol } |
    Select-Object -ExpandProperty symbol -First $N }

function BZ-Filters { param([string]$Sym) (($i=BZ-ExchangeInfo).symbols | ? { $_.symbol -eq $Sym }).filters }
function BZ-Step { param([double]$v,[double]$s) if($s -le 0){$v}else{ [math]::Floor($v/$s)*$s } }

# Ensure quote meets min notional (Binance uses NOTIONAL/MIN_NOTIONAL filters)
function BZ-EnsureMinNotional { param([string]$Sym,[double]$Quote)
  $f = BZ-Filters $Sym
  $not = $f | ? { $_.filterType -in @('NOTIONAL','MIN_NOTIONAL') } | Select-Object -First 1
  if($not -and $not.minNotional){
    $min = [double]$not.minNotional
    if($Quote -lt $min){ return [double]$min }
  }
  return $Quote
}

function BZ-BuyMkt { param([string]$Sym,[double]$Quote)
  $q = BZ-EnsureMinNotional $Sym $Quote
  BZ-Signed '/api/v3/order' 'POST' @{ symbol=$Sym; side='BUY'; type='MARKET'; quoteOrderQty=[string]$q; newOrderRespType='FULL' } }

function BZ-SellLimit { param([string]$Sym,[double]$Qty,[double]$Px)
  $f=BZ-Filters $Sym; $lot=[double]($f|?{$_.filterType -eq 'LOT_SIZE'}).stepSize; $tick=[double]($f|?{$_.filterType -eq 'PRICE_FILTER'}).tickSize
  $q=BZ-Step $Qty $lot; $p=[math]::Round((BZ-Step $Px $tick),10)
  BZ-Signed '/api/v3/order' 'POST' @{ symbol=$Sym; side='SELL'; type='LIMIT'; timeInForce='GTC'; quantity=[string]$q; price=[string]$p } }

function BZ-SellSL { param([string]$Sym,[double]$Qty,[double]$Px)
  $f=BZ-Filters $Sym; $lot=[double]($f|?{$_.filterType -eq 'LOT_SIZE'}).stepSize; $tick=[double]($f|?{$_.filterType -eq 'PRICE_FILTER'}).tickSize
  $q=BZ-Step $Qty $lot; $p=[math]::Round((BZ-Step $Px $tick),10)
  BZ-Signed '/api/v3/order' 'POST' @{ symbol=$Sym; side='SELL'; type='STOP_LOSS_LIMIT'; timeInForce='GTC'; quantity=[string]$q; stopPrice=[string]$p; price=[string]$p } }

function BZ-LastPx { param([string]$Sym) (BZ-Public '/api/v3/ticker/price' @{symbol=$Sym}).price -as [double] }

function BZ-RunMeme { param([int]$SelectTop=6,[double]$Quote=5,[double]$TpPct=1.0,[double]$SlPct=0.8)
  if(-not (BZ-TestCreds)){ return }
  $memes = BZ-TopMeme -N $SelectTop; if(-not $memes){ Write-Host "No MEME symbols." -ForegroundColor Yellow; return }
  $sym = $memes[0]; $px = BZ-LastPx $sym
  $buy = BZ-BuyMkt $sym $Quote
  $filled = ($buy.fills | Measure-Object qty -Sum).Sum; if(-not $filled){ $filled=$buy.executedQty }; [double]$qty=$filled
  $tp=$px*(1+$TpPct/100); $sl=$px*(1-$SlPct/100)
  BZ-SellLimit $sym ($qty*0.5) $tp | Out-Null
  BZ-SellSL    $sym ($qty*0.5) $sl | Out-Null
  [pscustomobject]@{ Symbol=$sym; EntryApprox=$px; Qty=$qty; TP=[math]::Round($tp,10); SL=[math]::Round($sl,10) }
}
# ===== END =====
