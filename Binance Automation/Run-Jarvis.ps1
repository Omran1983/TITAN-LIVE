param([int]$IntervalSec = 30)
$ErrorActionPreference='Stop'
$base = (Resolve-Path -LiteralPath .).Path
Remove-Item "$base\journal\STOP.txt" -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path "$base\journal" | Out-Null
$ts = Get-Date -Format 'yyyyMMdd_HHmm'
$pwsh = (Get-Command pwsh.exe).Source
$logOut = "$base\journal\loop_$ts.out.log"
$logErr = "$base\journal\loop_$ts.err.log"
Start-Process $pwsh -WorkingDirectory $base -WindowStyle Hidden `
  -ArgumentList @('-NoLogo','-NoProfile','-File', (Join-Path $base 'Jarvis-Loop.ps1'), '-Paper','-IntervalSec', "$IntervalSec") `
  -RedirectStandardOutput $logOut -RedirectStandardError $logErr
Start-Sleep 2
Write-Host "Launched. OUT: $logOut"
