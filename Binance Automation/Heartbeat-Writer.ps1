param(
  [Parameter(Mandatory)]
  [string]$CsvPath,
  [Parameter(Mandatory)]
  [string]$StopFlagPath
)
$ErrorActionPreference='Stop'
$rand = [Random]::new()
while ($true) {
  if (Test-Path $StopFlagPath) { break }
  $ts = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
  $sym='BTCUSDT'; $p=60000 + $rand.Next(-1000,1000); $qty=0.0001; $fee=0.00001
  $spread=$rand.Next(3,15); $slip=$rand.Next(-8,8); $flags='HEARTBEAT'
  $notional=[Math]::Round($p*$qty,6)
  Add-Content -Path $CsvPath -Value "$ts,$sym,BUY,$p,$p,$qty,$notional,$spread,$slip,$fee,HB-OPEN,$flags" -Encoding UTF8
  Start-Sleep -Seconds 2
  Add-Content -Path $CsvPath -Value "$ts,$sym,SELL,$p,$p,$qty,$notional,$spread,$slip,$fee,HB-CLOSE,$flags" -Encoding UTF8
  Start-Sleep -Seconds 300
}
