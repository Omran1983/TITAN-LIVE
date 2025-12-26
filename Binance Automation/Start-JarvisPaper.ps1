$ErrorActionPreference = "Stop"

# Correct Base = current folder (not parent)
$Base = (Resolve-Path -LiteralPath .).Path

# journal + today csv
$Journal = Join-Path $Base 'journal'
New-Item -ItemType Directory -Force -Path $Journal | Out-Null
$Today = Get-Date -Format 'yyyy-MM-dd'
$Csv   = Join-Path $Journal ("paper_trades_{0}.csv" -f $Today)
if (-not (Test-Path $Csv)) {
  'ts_utc,symbol,side,intended_price,filled_price,qty,notional_usdt,spread_bps,slippage_bps,fee_usdt,reason,breaker_flags' |
    Set-Content -Path $Csv -Encoding UTF8
}

$env:JARVIS_MODE = 'PAPER'

# Clear stop flag so the writer can run
$StopFlag = Join-Path $Base 'STOP-PAPER.flag'
if (Test-Path $StopFlag) { Remove-Item $StopFlag -Force -ErrorAction SilentlyContinue }

# If your real loop exists you can launch it here; for now we always run the writer as a detached pwsh
$writer = Join-Path $Base 'Heartbeat-Writer.ps1'
$pwsh   = (Get-Command pwsh.exe -ErrorAction SilentlyContinue)?.Source
if (-not $pwsh) { $pwsh = 'C:\Program Files\PowerShell\7\pwsh.exe' }
if (!(Test-Path $pwsh)) { throw "pwsh.exe not found at: $pwsh" }

Start-Process -FilePath $pwsh -WorkingDirectory $Base -WindowStyle Hidden -ArgumentList @(
  '-NoLogo','-NoProfile','-File',"`"$writer`"",
  '-CsvPath', "`"$Csv`"",
  '-StopFlagPath', "`"$StopFlag`""
) | Out-Null

Write-Host "[Start-JarvisPaper] Ready. Journal: $Csv"
