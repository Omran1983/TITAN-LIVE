param(
  [string]$BaseUrl = "https://api.binance.com",
  [int]$RecvWindowMs = 2000,
  [string[]]$ProbeSymbols = @('DOGEUSDT','SHIBUSDT','PEPEUSDT'),
  [int]$MinDepthUSD = 10000,
  [int]$MaxSpreadBps = 12
)
$Root  = if ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
$repDir = Join-Path $Root "preflight"; if (-not (Test-Path $repDir)) { New-Item -ItemType Directory -Force -Path $repDir | Out-Null }
$repJson = Join-Path $repDir ("preflight_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".json")

function HmacSHA256Hex([string]$msg, [string]$secret) { $h=New-Object System.Security.Cryptography.HMACSHA256; $h.Key=[Text.Encoding]::UTF8.GetBytes($secret); ($h.ComputeHash([Text.Encoding]::UTF8.GetBytes($msg))|%{ $_.ToString("x2") })-join '' }
function Get-ServerTime { try { Invoke-RestMethod "$BaseUrl/api/v3/time" -TimeoutSec 10 } catch { $null } }
function Get-AccountStatus { param([string]$Key,[string]$Secret); $ts=[int64]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()); $q="timestamp=$ts&recvWindow=$RecvWindowMs"; $sig=HmacSHA256Hex $q $Secret; $url="$BaseUrl/sapi/v1/account/status?$q&signature=$sig"; try { Invoke-RestMethod -Uri $url -Headers @{ "X-MBX-APIKEY"=$Key } -TimeoutSec 15 } catch { $_ } }
function Get-ExchangeInfo { try { Invoke-RestMethod "$BaseUrl/api/v3/exchangeInfo" -TimeoutSec 20 } catch { $null } }
function Get-BookTicker([string]$sym){ try { Invoke-RestMethod "$BaseUrl/api/v3/ticker/bookTicker?symbol=$sym" -TimeoutSec 10 } catch { $null } }
function Get-Depth([string]$sym,[int]$limit=5){ try { Invoke-RestMethod "$BaseUrl/api/v3/depth?symbol=$sym&limit=$limit" -TimeoutSec 10 } catch { $null } }

$report = [ordered]@{}
$report.ts=(Get-Date).ToString("s"); $report.base_url=$BaseUrl; $report.recv_window_ms=$RecvWindowMs; $report.min_depth_usd=$MinDepthUSD; $report.max_spread_bps=$MaxSpreadBps
$report.errors=@(); $report.probes=@()

$envBlock=[ordered]@{}
if ($env:BINANCE_API_KEY){ $tail=if($env:BINANCE_API_KEY.Length -ge 4){$env:BINANCE_API_KEY.Substring($env:BINANCE_API_KEY.Length-4)}else{$env:BINANCE_API_KEY}; $envBlock.BINANCE_API_KEY="***$tail" } else { $envBlock.BINANCE_API_KEY=$null; $report.errors+="BINANCE_API_KEY missing" }
if ($env:BINANCE_API_SECRET){ $envBlock.BINANCE_API_SECRET="present" } else { $envBlock.BINANCE_API_SECRET=$null; $report.errors+="BINANCE_API_SECRET missing" }
$report.env=$envBlock

$svr=Get-ServerTime
if($svr){ $report.server_time=$svr.serverTime; $local=[int64]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()); $report.clock_skew_ms=[int64]$svr.serverTime-$local } else { $report.errors+="ServerTime call failed" }

if ($env:BINANCE_API_KEY -and $env:BINANCE_API_SECRET){
  $acct=Get-AccountStatus -Key $env:BINANCE_API_KEY -Secret $env:BINANCE_API_SECRET
  if($acct -is [System.Management.Automation.ErrorRecord]){ $report.account_status=@{ error=$acct.Exception.Message; body= if($acct.ErrorDetails.Message){$acct.ErrorDetails.Message}else{$null} }; $report.errors+="Account status error (perm/IP)." } else { $report.account_status=$acct }
}

$ex=Get-ExchangeInfo; if(-not $ex){ $report.errors+="exchangeInfo fetch failed" }; $report.exchange_info= if($ex){"ok"}else{"error"}

function SumUSD($side){ $s=0.0; foreach($lvl in $side){ $s += ([double]$lvl[0]*[double]$lvl[1]) }; [math]::Round($s,2) }
foreach($sym in $ProbeSymbols){
  $probe=[ordered]@{ symbol=$sym; ok=$false }
  $bt=Get-BookTicker $sym; $dp=Get-Depth $sym 5
  if(-not $bt -or -not $dp){ $probe.reason="bookTicker/depth failed"; $report.probes+=$probe; continue }
  $bid=[double]$bt.bidPrice; $ask=[double]$bt.askPrice; $mid= if($ask -gt 0){($bid+$ask)/2.0}else{0}
  $spread= if($mid -gt 0){ (($ask-$bid)/$mid)*10000 } else { 99999 }
  $top=[math]::Min( (SumUSD $dp.bids),(SumUSD $dp.asks) )
  $probe.bid=$bid; $probe.ask=$ask; $probe.spread_bps=[math]::Round($spread,2); $probe.depth_usd=$top
  $probe.pass_spread= ($spread -le $MaxSpreadBps); $probe.pass_depth= ($top -ge $MinDepthUSD); $probe.ok= ($probe.pass_spread -and $probe.pass_depth)
  $report.probes += $probe
}

$bad= ($report.probes | Where-Object { -not $_.ok }).Count
$report.verdict = if( ($report.errors.Count -eq 0) -and ($bad -eq 0) ){"READY"}else{"BLOCKED"}

($report | ConvertTo-Json -Depth 6) | Set-Content -Encoding UTF8 $repJson
Write-Host "=== Preflight Verdict: $($report.verdict) ==="
Write-Host "Report -> $repJson"
if($report.errors.Count -gt 0){ Write-Host "Errors:" -ForegroundColor Yellow; $report.errors | % { Write-Host " - $_" } }
Write-Host "`nProbes:" -ForegroundColor Cyan
$report.probes | % { "{0,-12} spread={1,6} bps  depth=${2,10}  OK={3}" -f $_.symbol,$_.spread_bps,$_.depth_usd,$_.ok }
