# ----- CREATE FILE: .\Jarvis-Today-Realized.ps1 -----
$ErrorActionPreference='Stop'
function Import-DotEnv {
  param([string]$Path = ".\.env")
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
function New-QueryStringSorted([hashtable]$Params){ ($Params.GetEnumerator()|Sort-Object Key|%{"{0}={1}" -f $_.Key,$_.Value}) -join '&' }
function Sign-Query($qs,$sec){ $h=[System.Security.Cryptography.HMACSHA256]::new([Text.Encoding]::UTF8.GetBytes($sec)); try{($h.ComputeHash([Text.Encoding]::UTF8.GetBytes($qs))|%{$_.ToString('x2')}) -join ''}finally{$h.Dispose()} }
function Get-BinanceServerUnixMs { $t0=[DateTimeOffset]::UtcNow; $srv=Invoke-RestMethod -Method GET -Uri "https://api.binance.com/api/v3/time"; $t1=[DateTimeOffset]::UtcNow; [int64]$srv.serverTime + [int64](($t1-$t0).TotalMilliseconds/2) }
function Invoke-BinanceSigned([string]$Method,[string]$Path,[hashtable]$Params){ if(-not $Params){$Params=@{}}; if(-not $Params.ContainsKey('recvWindow')){$Params.recvWindow=5000}; $Params.timestamp=Get-BinanceServerUnixMs; $qs=New-QueryStringSorted $Params; $sig=Sign-Query $qs $env:BINANCE_SECRET_KEY; $u=[System.UriBuilder]::new("https://api.binance.com"); $p=if($Path.StartsWith('/')){$Path}else{"/$Path"}; $u.Path=($u.Path.TrimEnd('/')+$p); $u.Query="$qs&signature=$sig"; Invoke-RestMethod -Method $Method -Uri $u.Uri.AbsoluteUri -Headers @{ 'X-MBX-APIKEY'=$env:BINANCE_API_KEY } }
$syms=@('BTCUSDT','ETHUSDT','DOGEUSDT','PEPEUSDT','SHIBUSDT','WIFUSDT','FLOKIUSDT','BONKUSDT')
$now=[DateTimeOffset]::UtcNow; $mid=[DateTimeOffset]::new($now.Year,$now.Month,$now.Day,0,0,0,[TimeSpan]::Zero); $since=[int64]$mid.ToUnixTimeMilliseconds()
$rows=@()
foreach($s in $syms){
  try{
    $t=Invoke-BinanceSigned 'GET' '/api/v3/myTrades' @{symbol=$s; startTime=$since; limit=1000}
    if($t){
      $buy=($t|? isBuyer|Measure-Object -Property quoteQty -Sum).Sum
      $sell=($t|? { -not $_.isBuyer }|Measure-Object -Property quoteQty -Sum).Sum
      $rows+=[pscustomobject]@{Symbol=$s; RealizedToday_USDT=[math]::Round(([double]$sell-[double]$buy),6); Trades=$t.Count}
    }
  }catch{}
  Start-Sleep -Milliseconds 60
}
$rows|?{$_.Trades -gt 0}|Sort-Object RealizedToday_USDT|Format-Table -Auto
"TOTAL today: {0:N6} USDT" -f (($rows|Measure-Object -Property RealizedToday_USDT -Sum).Sum)

