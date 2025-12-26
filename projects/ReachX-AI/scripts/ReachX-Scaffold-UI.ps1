param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePage,           # e.g. "dormitories.html"

    [Parameter(Mandatory = $true)]
    [string]$NewPage,              # e.g. "calls.html"

    [Parameter(Mandatory = $true)]
    [hashtable]$Replacements       # key => value text replacements
)

$ErrorActionPreference = "Stop"

$uiRoot = "F:\ReachX-AI\infra\ReachX-Workers-UI-v1"
$src    = Join-Path $uiRoot $SourcePage
$dst    = Join-Path $uiRoot $NewPage

if (!(Test-Path $src)) {
    throw "Source page not found: $src"
}

Write-Host "Scaffolding $NewPage from $SourcePage..." -ForegroundColor Cyan

$content = Get-Content $src -Raw

foreach ($key in $Replacements.Keys) {
    $from = [regex]::Escape($key)
    $to   = [string]$Replacements[$key]
    $content = [regex]::Replace($content, $from, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $to })
}

Set-Content -Path $dst -Value $content -Encoding UTF8

Write-Host "Created: $dst" -ForegroundColor Green
