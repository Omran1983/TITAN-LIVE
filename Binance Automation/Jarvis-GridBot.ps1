param(
  [string]$Symbol = 'BTCUSDT',
  [decimal]$InvestUSDT = 40,
  [decimal]$RangePct = 4,
  [int]$Grids = 8,
  [switch]$Live    # <- add -Live to actually place orders
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function CallPublic([string]$path,[hashtable]$p){
  $base = "https://api.binance.com"
  $qs = if($p){ ($p.GetEnumerator() | Sort-Object Name | ForEach-Object {
      [System.Uri]::EscapeDataString($_.Key) + '=' + [System.Uri]::EscapeDataString([string]$_.Value)
    }) -join '&' } else { '' }
  $uri = if($qs){ ('{0}{1}?{2}' -f $base,$path,$qs) } else { ('{0}{1}' -f $base,$path) }
  Invoke-RestMethod -Method GET -Uri $uri
}
function NewSig([string]$q,[string]$sec){
  $h=[System.Security.Cryptography.HMACSHA256]::new([Text.Encoding]::UTF8.GetBytes($sec))
  ($h.ComputeHash([Text.Encoding]::UTF8.GetBytes($q))|ForEach-Object{$_.ToString('x2')}) -join ''
}
function CallSigned([string]$method,[string]$path,[hashtable]$p){
  $api=$Env:BINANCE_API_KEY; $sec=$Env:BINANCE_SECRET_KEY
  if([string]::IsNullOrWhiteSpace($api) -or [string]::IsNullOrWhiteSpace($sec)){ throw "Missing BINANCE_API_KEY / BINANCE_SECRET_KEY." }
  if(-not $p){ $p=@{} }
  if(-not $p['timestamp']){ $p['timestamp']=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
  if(-not $p['recvWindow']){ $p['recvWindow']=5000 }
  $qs=($p.GetEnumerator()|Sort-Object Name|ForEach-Object{[uri]::EscapeDataString($_.Key)+'='+[uri]::EscapeDataString([string]$_.Value)})-join'&'
  $sig=NewSig $qs $sec
  $uri=('{0}{1}?{2}&signature={3}' -f 'https://api.binance.com',$path,$qs,$sig)
  $hdr=@{'X-MBX-APIKEY'=$api}
  Invoke-RestMethod -Method $method -Uri $uri -Headers $hdr
}
function RoundToStep([decimal]$v,[decimal]$step){ if($step -le 0){return $v}; [decimal]([math]::Floor($v/$step)*$step) }

# --- Exchange info & filters ---
$ex = CallPublic "/api/v3/exchangeInfo" @{}
$sy = $ex.symbols | Where-Object { $_.symbol -eq $Symbol } | Select-Object -First 1
if(-not $sy){ throw "Symbol $Symbol not found." }
$filters = @{}; foreach($f in $sy.filters){ $filters[$f.filterType]=$f }
$lotStep = [decimal]$filters.LOT_SIZE.stepSize
$minQty  = [decimal]$filters.LOT_SIZE.minQty
$minNot  = if ($filters.NOTIONAL) { [decimal]$filters.NOTIONAL.minNotional } elseif ($filters.MIN_NOTIONAL) { [decimal]$filters.MIN_NOTIONAL.minNotional } else { 5 }

# --- Mid price ---
$ticks = CallPublic "/api/v3/ticker/price" @{}
$mid = [decimal]($ticks | Where-Object { $_.symbol -eq $Symbol } | Select-Object -ExpandProperty price)
if($mid -le 0){ throw "Bad mid price for $Symbol." }

# --- Range & grid levels (arithmetic) ---
$lower = [decimal]([math]::Round($mid*(1-$RangePct/100), 2))
$upper = [decimal]([math]::Round($mid*(1+$RangePct/100), 2))
if($Grids -lt 2){ throw "Grids must be >= 2." }
$levels=@(); for($i=0;$i -lt $Grids;$i++){ $levels += [decimal]($lower + ($upper-$lower)*$i/([decimal]($Grids-1))) }
$levels = $levels | ForEach-Object { [decimal]([math]::Round($_,2)) }

# --- Sizing per order ---
$perOrderQuote = [decimal]([math]::Max($InvestUSDT / [math]::Max($Grids-1,1), 5))
$buys  = $levels | Where-Object { $_ -lt $mid }
$sells = $levels | Where-Object { $_ -gt $mid }
$buyPlan = foreach($p in $buys){ $q = RoundToStep ([decimal]($perOrderQuote / $p)) $lotStep; if($q -ge $minQty -and ($q*$p) -ge $minNot){ [pscustomobject]@{ Side='BUY';  Price=$p; Qty=$q } } }
$defaultSellQty = if($buyPlan){ ($buyPlan | Select-Object -Last 1).Qty } else { 0 }
$sellPlan = foreach($p in $sells){ $q = RoundToStep $defaultSellQty $lotStep; if($q -ge $minQty -and ($q*$p) -ge $minNot){ [pscustomobject]@{ Side='SELL'; Price=$p; Qty=$q } } }

Write-Host ("== PLAN {0} mid={1} range=[{2},{3}] grids={4} perOrder≈{5}" -f $Symbol,$mid,$lower,$upper,$Grids,$perOrderQuote)
Write-Host ("lotStep={0} minQty={1} minNotional={2}  Buys={3} Sells={4}" -f $lotStep,$minQty,$minNot,$buyPlan.Count,$sellPlan.Count)

if(-not $buyPlan -or -not $sellPlan){ Write-Warning "Orders too small. Reduce grids or raise InvestUSDT."; exit }

# --- Tag + cancel previous tagged orders ---
$tag = ("JRV_{0}" -f ([guid]::NewGuid().ToString('N').Substring(0,6)).ToUpper())
function CancelTagged(){
  $open = CallSigned 'GET' '/api/v3/openOrders' @{symbol=$Symbol}
  $mine = $open | Where-Object { $_.clientOrderId -like "JRV_*" }
  foreach($o in $mine){
    if($Live){ CallSigned 'DELETE' '/api/v3/order' @{symbol=$Symbol; orderId=$o.orderId} | Out-Null; "CANCELED $($o.side) @$($o.price)" | Write-Host }
    else { "DRY cancel $($o.side) @$($o.price)" | Write-Host }
  }
}

function Place([string]$side,[decimal]$price,[decimal]$qty){
  $cid = ("{0}-{1}-{2}" -f $tag,$side,[string]$price); $cid = ($cid -replace '[^a-zA-Z0-9-_]',''); if($cid.Length -gt 36){ $cid = $cid.Substring(0,36) }
  $p = @{ symbol=$Symbol; side=$side; type='LIMIT'; timeInForce='GTC'; quantity=$qty; price=$price; newClientOrderId=$cid }
  if($Live){ CallSigned 'POST' '/api/v3/order' $p | Out-Null; "LIVE placed $side @ $price qty $qty (cid=$cid)" | Write-Host }
  else { "DRY place $side @ $price qty $qty (cid=$cid)" | Write-Host }
}

# --- Deploy ---
CancelTagged | Out-Null
$buyPlan  | ForEach-Object { Place 'BUY'  $_.Price $_.Qty }
# SELLs disabled; armed after fills

Write-Host ("Done. Mode={0}. Tag={1}. Re-run to refresh grid." -f ($(if($Live){'LIVE'}else{'DRY'})),$tag)




