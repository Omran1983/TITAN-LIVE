<# =====================  Jarvis-Lock-Benchmark.ps1  =====================
Creates a timestamped ZIP backup of the current "Binance Automation" folder.
Safe, idempotent. Works even if run from console/ISE (no script path).
USAGE:
  pwsh -NoLogo -NoProfile -File .\Jarvis-Lock-Benchmark.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Robust script root detection ---
$root = if ($PSScriptRoot -and $PSScriptRoot.Trim()) {
  $PSScriptRoot
} elseif ($PSCommandPath -and $PSCommandPath.Trim()) {
  Split-Path -Parent $PSCommandPath
} else {
  (Get-Location).Path
}

# Normalize path (remove trailing separators)
$root = [System.IO.Path]::GetFullPath($root)

$stamp     = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = Join-Path $root 'backup'
$newZip    = Join-Path $backupDir "$stamp-JarvisBenchmark.zip"

Write-Host "Root: $root"
Write-Host "Backup dir: $backupDir"
Write-Host "Target zip: $newZip"

New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# Exclude the backup directory itself from the copy
$items = Get-ChildItem -LiteralPath $root -Force | Where-Object { $_.Name -ne 'backup' }

# Stage to a temp folder to avoid file locks during compression
$temp = Join-Path $backupDir ".$stamp-staging"
if (Test-Path $temp) { Remove-Item $temp -Recurse -Force }
New-Item -ItemType Directory -Path $temp -Force | Out-Null

foreach ($i in $items) {
  Copy-Item -Path $i.FullName -Destination (Join-Path $temp $i.Name) -Recurse -Force -ErrorAction Stop
}

if (Test-Path $newZip) { Remove-Item $newZip -Force }

# Compress the staged content
Compress-Archive -Path (Join-Path $temp '*') -DestinationPath $newZip -Force

# Clean up staging
Remove-Item $temp -Recurse -Force

Write-Host "✅ Benchmark locked at: $newZip"
