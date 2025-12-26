# Jarvis-MemeScanner.ps1
param(
  [string] $BaseUrl = $Env:BINANCE_BASE_URL,
  [int]    $TopN = 6,
  [double] $Min24hQuoteVol = 10000000,  # $10M
  [double] $MaxSpreadBps = 20,          # 0.20%
  [double] $MinDepthUSD = 25000,        # $25k
  [switch] $VerboseSignals
)
$ErrorActionPreference = 'Stop'
if (-not $BaseUrl) { $BaseUrl = "https://api.binance.com" }

function GET([string]$path,[hashtable]$q=@{}) {
  $qs = ($q.GetEnumerator()|Sort-Object Name|%{ "{0}={1}" -f $_.Name,[uri]::EscapeDataString([string]$_.Value) }) -join "&"
  $u = if($qs){"$BaseUrl$path`?$qs"}else{"$BaseUrl$path"}
  Invoke-RestMethod -Uri $u -Headers @{ "X-MBX-APIKEY" = $Env:BINANCE_API_KEY }
}
function Get-24h(){ GET '/api/v3/ticker/24hr' }
function Get-BookTicker([string]$s){ GET '/api/v3/ticker/bookTicker' @{symbol=$s} }
function Get-Klines([string]$s,[string]$i,[int]$l=200){ GET '/api/v3/klines' @{symbol=$s;interval=$i;limit=$l} }
function Get-ExchangeInfo(){ GET '/api/v3/exchangeInfo' }

function EMA([double[]]$a,[int]$n){ if($a.Count -lt $n){return @()} $k=2.0/($n+1)
  $ema=[System.Collections.Generic.List[double]]::new()
  $sma=($a[0..($n-1)]|measure -Average).Average; $ema.Add([double]$sma)|Out-Null
  for($i=$n;$i -lt $a.Count;$i++){ $ema.Add(($a[$i]*$k)+($ema[$ema.Count-1]*(1-$k)))|Out-Null } $ema }
function ATR($h,$l,$c,[int]$n){ $m=$c.Count;if($m -lt ($n+1)){return @()}
  $trs=[System.Collections.Generic.List[double]]::new()
  for($i=1;$i -lt $m;$i++){ $tr1=$h[$i]-$l[$i];$tr2=[math]::Abs($h[$i]-$c[$i-1]);$tr3=[math]::Abs($l[$i]-$c[$i-1]);$trs.Add([double]([math]::Max($tr1,[math]::Max($tr2,$tr3))))|Out-Null}
  $atr=[System.Collections.Generic.List[double]]::new();$atr0=($trs[0..($n-1)]|measure -Average).Average;$atr.Add([double]$atr0)|Out-Null
  for($i=$n;$i -lt $trs.Count;$i++){ $atr.Add(($atr[$atr.Count-1]*($n-1)+$trs[$i])/$n)|Out-Null } $atr }
function BB([double[]]$c,[int]$n=20,[double]$k=2.0){ if($c.Count -lt $n){return @()}
  $out=[System.Collections.Generic.List[object]]::new()
  for($i=$n-1;$i -lt $c.Count;$i++){ $w=$c[($i-$n+1)..$i];$avg=($w|measure -Average).Average
    $var=($w|%{($_-$avg)*($_-$avg)}|measure -Average).Average;$sd=[math]::Sqrt($var)
    $out.Add(@($avg-$k*$sd,$avg,$avg+$k*$sd))|Out-Null } $out }
function ZScore([double[]]$a){ $avg=($a|measure -Average).Average;$var=($a|%{($_-$avg)*($_-$avg)}|measure -Average).Average;$sd=[math]::Sqrt($var)
  if($sd -eq 0){return ($a|%{0.0})} ($a|%{($_-$avg)/$sd}) }

function Build-MemeUniverse{
  $tick=Get-24h; $info=Get-ExchangeInfo; $trad=@{}
  foreach($s in $info.symbols){ if($s.status -eq 'TRADING'){$trad[$s.symbol]=$true} }
  $memes=@('DOGE','SHIB','PEPE','FLOKI','BONK','WIF','BRETT','WEN','POPCAT','MEW','MOEW','PONKE','SLERF','CAT','DOG','INU','FROG','BULL','MEME')
  $out=[System.Collections.Generic.List[object]]::new()
  foreach($t in $tick){
    if(-not $t.symbol.EndsWith('USDT')){continue}
    if(-not $trad.ContainsKey($t.symbol)){continue}
    $qv=[double]$t.quoteVolume; if($qv -lt 10000000){continue}
    $base=$t.symbol.Substring(0,$t.symbol.Length-4)
    if($memes|Where-Object{ $base -like "*$_*" }){ $out.Add([pscustomobject]@{sym=$t.symbol;qv=$qv})|Out-Null }
  }
  $out|Sort-Object qv -Descending|%{ $_.sym }
}

function Score-Symbol([string]$sym){
  try{
    $bt=Get-BookTicker $sym; $bid=[double]$bt.bidPrice; $ask=[double]$bt.askPrice
    if($bid -le 0 -or $ask -le 0){return $null}
    $spreadBps=(($ask-$bid)/$ask)*10000; if($spreadBps -gt $MaxSpreadBps){return $null}
    $depthUSD=($bid*[double]$bt.bidQty)+($ask*[double]$bt.askQty); if($depthUSD -lt $MinDepthUSD){return $null}
    $k1=Get-Klines $sym '1m' 200; $k5=Get-Klines $sym '5m' 200; if(-not $k1 -or $k1.Count -lt 60){return $null}
    $cl1=@();$hi1=@();$lo1=@();$vol1=@(); foreach($k in $k1){$cl1+=[double]$k[4];$hi1+=[double]$k[2];$lo1+=[double]$k[3];$vol1+=[double]$k[5]}
    $price=$cl1[-1]
    $ema8=EMA $cl1 8; $ema21=EMA $cl1 21; if($ema21.Count -eq 0){return $null}; $ema8c=$ema8[-1];$ema21c=$ema21[-1]
    $atr1=ATR $hi1 $lo1 $cl1 14; if($atr1.Count -eq 0){return $null}; $atrNow=$atr1[-1]; $atrPct=($atrNow/$price)*100
    $w=20; if($vol1.Count -lt $w){return $null}; $num=0.0;$den=0.0
    for($i=$cl1.Count-$w;$i -lt $cl1.Count;$i++){ $typ=($hi1[$i]+$lo1[$i]+$cl1[$i])/3.0; $v=[double]$vol1[$i]; $num+=$typ*$v; $den+=$v }
    if($den -eq 0){return $null}; $vwap=$num/$den
    $zv=ZScore $vol1; $zNow=$zv[-1]; $sorted=$vol1|Sort-Object; $medianVol=$sorted[[int][math]::Floor($sorted.Count/2)]
    $volMult=$vol1[-1]/[math]::Max(1e-9,$medianVol)
    $cl5=@(); foreach($x in $k5){ $cl5+=[double]$x[4] }; if($cl5.Count -lt 3 -or $cl5[-2] -eq 0){return $null}
    $rs=($cl5[-1]/$cl5[-2])-1.0
    $bb=BB $cl1 20 2.0; if($bb.Count -eq 0){return $null}; $bbLast=$bb[-1]; $bbU=[double]$bbLast[2]; $bbL=[double]$bbLast[0]
    $mom=($ema8c -gt $ema21c) -and ($price -gt $vwap)
    $volOK=($atrPct -ge 0.5) -and ($atrPct -le 4.0)
    $brk=($price -ge $bbU) -and ($price -le ($bbU*1.01))
    $volThrust=($zNow -ge 2.0) -and ($volMult -ge 2.0)
    if(-not ($mom -and $volOK -and $brk -and $volThrust)){ return $null }
    $score=0; if($mom){$score+=20}; if($volThrust){$score+=30}; if($volOK){$score+=15}; if($rs -gt 0){$score+=[math]::Min(15,[math]::Round($rs*100,2))}; if($brk){$score+=10}
    $micro=10; if($depthUSD -ge ($MinDepthUSD*2)){$micro+=2}; $score += [math]::Min(10,$micro)
    [pscustomobject]@{symbol=$sym;price=[math]::Round($price,10);score=[math]::Round($score,1);volZ=[math]::Round($zNow,2);volX=[math]::Round($volMult,2);atrPct=[math]::Round($atrPct,3);rs5m=[math]::Round($rs*100,2);spreadBps=[math]::Round($spreadBps,2);depthUSD=[math]::Round($depthUSD,0)}
  } catch { return $null }
}

Write-Host "=== JARVIS Meme Scanner (study only) ===" -ForegroundColor Cyan
$u = Build-MemeUniverse
if(-not $u -or $u.Count -eq 0){ Write-Host "No candidates after liquidity filter." -ForegroundColor Yellow; exit }
$r=[System.Collections.Generic.List[object]]::new()
foreach($s in $u){ $x=Score-Symbol $s; if($x){$r.Add($x)|Out-Null} }
if($r.Count -eq 0){ Write-Host "No symbols passed signal thresholds. Standing down." -ForegroundColor Yellow; exit }
$top=$r|Sort-Object score -Descending|Select-Object -First $TopN
$top|Format-Table symbol,price,score,volZ,volX,atrPct,rs5m,spreadBps,depthUSD -AutoSize
if($VerboseSignals){ "`n--- Details ---"; $top|Format-List * }
"`nGuidance: Trade only if score ≥ 70 and spread ≤ $MaxSpreadBps bps. Use $5–$10 per scalp within your $44 budget."
