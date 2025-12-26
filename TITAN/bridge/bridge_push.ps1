$ErrorActionPreference = "Stop"

$BridgeDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TitanRoot = Resolve-Path (Join-Path $BridgeDir "..")
$Outbox = Join-Path $TitanRoot "io\outbox"

if (-not (Test-Path $Outbox)) {
    Write-Host "❌ Outbox not found: $Outbox" -ForegroundColor Red
    exit 1
}

$latest = Get-ChildItem -Path $Outbox -Filter "result_*.json" |
Sort-Object LastWriteTime -Descending |
Select-Object -First 1

if (-not $latest) {
    Write-Host "❌ No result_*.json found in outbox." -ForegroundColor Red
    exit 1
}

$content = Get-Content -Raw -Encoding UTF8 $latest.FullName
Set-Clipboard -Value $content

Write-Host "✅ Latest result copied to clipboard:" -ForegroundColor Green
Write-Host $latest.FullName
