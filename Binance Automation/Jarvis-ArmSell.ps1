param(
  [string]$Symbol = 'BTCUSDT',
  [decimal]$RangePct = 4,
  [int]$Grids = 8,
  [switch]$Live
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function CallPublic([string]$path,[hashtable]$p){
  $base='https://api.binance.com'
  $qs = if($p){ ($p.GetEnumerator()|Sort-Object Name|%{[uri]::EscapeDataString($_.Key)+'='+[uri]::EscapeDataString([string]$_.Value)}) -join '&' } else { '' }
  $uri = if($qs){ ('{0}{1}?{2}' -f $base,$path,$qs) } else { ('{0}{1}' -f $base,$path) }
  Invoke-RestMethod -Method GET -Uri $uri
}
function NewSig([string]$q,[string]$sec){
  $h=[System.Security.Cryptography.HMACSHA256]::new([Text.Encoding]::UTF8.GetBytes($sec))
  ($h.ComputeHash([Text.Encoding]::UTF8.GetBytes($q))|%{$_.ToString('x2')}) -join ''
}
function CallSigned([string]$method,[string]$path,[hashtable]$p){
  $api=$Env:BINANCE_API_KEY; $sec=$Env:BINANCE_SECRET_KEY
  if([string]::IsNullOrWhiteSpace($api) -or [string]::IsNullOrWhiteSpace($sec)){ throw "Missing BINANCE_API_KEY/SECRET" }
  if(-not $p){ $p=@{} }
  if(-not $p.ContainsKey('timestamp')){ $p['timestamp']=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() }
  if(-not $p.ContainsKey('recvWindow')){ $p['recvWindow']=5000 }
  $qs=($p.GetEnumerator()|Sort-Object Name|%{[uri]::EscapeDataString($_.Key)+'='+[uri]::EscapeDataString([string]$_.Value)}) -join '&'
  $sig=NewSig $qs $sec
  $uri=('https://api.binance.com{0}?{1}&signature={2}' -f $path,$qs,$sig)
  $hdr=@{'X-MBX-APIKEY'=$api}
  Invoke-RestMethod -Method $method -Uri $uri -Headers $hdr
}
function RoundToStep([decimal]$v,[decimal]$step){
  if($step -le 0){ return $v }
  [decimal]([math]::Floor($v/$step)*$step)
}

# Exchange filters
$ex = CallPublic "/api/v3/exchangeInfo" @{}
$sy = $ex.symbols | ?{ $_.symbol -eq $Symbol } | Select-Object -First 1
if(-not $sy){ throw "Symbol $Symbol not found." }
$filters=@{}; foreach($f in $sy.filters){ $filters[$f.filterType]=$f }
$lotStep=[decimal]$filters.LOT_SIZE.stepSize
$minQty =[decimal]$filters.LOT_SIZE.minQty
$minNot = if($filters.NOTIONAL){ [decimal]$filters.NOTIONAL.minNotional } elseif($filters.MIN_NOTIONAL){ [decimal]$filters.MIN_NOTIONAL.minNotional } else { 5 }

# Mid & grid
$mid=[decimal]((CallPublic "/api/v3/ticker/price" @{symbol=$Symbol}).price)
$lower=[decimal]([math]::Round($mid*(1-$RangePct/100),2))
$upper=[decimal]([math]::Round($mid*(1+$RangePct/100),2))
$step =[decimal]([math]::Round(($upper-$lower)/([decimal]($Grids-1)),2))

# Last BUY fill
$trades = CallSigned 'GET' '/api/v3/myTrades' @{ symbol=$Symbol; limit=100 }
$buy = $trades | ?{ $_.isBuyer } | Sort-Object time -Desc | Select-Object -First 1
if(-not $buy){ Write-Host "No BUY fills yet — nothing to arm."; exit 0 }

$fillP=[decimal]$buy.price
$qty  =[decimal]$buy.qty

# Snap SELL one grid above fill
$k=[math]::Ceiling(($fillP - $lower)/$step)
$sellP=[decimal]([math]::Round($lower + $k*$step, 2))

# Round qty to lot & verify notional
$qty = RoundToStep $qty $lotStep
if($qty -lt $minQty -or ($qty*$sellP) -lt $minNot){ throw "Qty/notional too small: qty=$qty sellP=$sellP minQty=$minQty minNot=$minNot" }

# Place SELL
$cid = ("JRVSELL-{0}-{1}" -f $Symbol,$sellP) -replace '[^a-zA-Z0-9-_]',''
if($cid.Length -gt 36){ $cid=$cid.Substring(0,36) }

$p=@{ symbol=$Symbol; side='SELL'; type='LIMIT'; timeInForce='GTC'; quantity=$qty; price=$sellP; newClientOrderId=$cid }
if($Live){ CallSigned 'POST' '/api/v3/order' $p | Out-Null; "LIVE: SELL armed @ $sellP qty $qty" | Write-Host }
else     { "DRY: would SELL @ $sellP qty $qty" | Write-Host }
