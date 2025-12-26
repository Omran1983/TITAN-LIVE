$ErrorActionPreference = "Stop"

$BridgeDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TitanRoot = Resolve-Path (Join-Path $BridgeDir "..")
$Inbox = Join-Path $TitanRoot "io\inbox"
$Outbox = Join-Path $TitanRoot "io\outbox"

Write-Host "=== TITAN BRIDGE STATUS ==="

if (Test-Path $Inbox) {
    $pending = Get-ChildItem -Path $Inbox -Filter "*.json" | Where-Object { $_.Name -notmatch "\.(done|failed|invalid)$" }
    Write-Host "Inbox pending:" $pending.Count
    $pending | Select-Object -First 5 | ForEach-Object { Write-Host " - $($_.Name)" }
}
else {
    Write-Host "Inbox missing"
}

if (Test-Path $Outbox) {
    $latest = Get-ChildItem -Path $Outbox -Filter "result_*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) {
        Write-Host "Latest result:" $latest.Name
        Write-Host "Updated:" $latest.LastWriteTime
    }
    else {
        Write-Host "No results yet."
    }
}
else {
    Write-Host "Outbox missing"
}
