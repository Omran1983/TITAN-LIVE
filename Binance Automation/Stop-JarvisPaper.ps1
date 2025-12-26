$ErrorActionPreference = "Stop"
$Base = (Resolve-Path -LiteralPath .).Path
$StopFlag = Join-Path $Base 'STOP-PAPER.flag'
New-Item -ItemType File -Path $StopFlag -Force | Out-Null
Write-Host "[Stop-JarvisPaper] Stop flag dropped; writer will exit shortly."
