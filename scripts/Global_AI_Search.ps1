param(
    [string]$Query = "AI Innovation"
)

Write-Host "=== Global_AI_Search (Wrapper) ===" -ForegroundColor Cyan
Write-Host "Redirecting to Jarvis-SearchKnowledge..." -ForegroundColor DarkGray

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$target    = Join-Path $scriptDir "Jarvis-SearchKnowledge.ps1"

if (Test-Path $target) {
    & $target -Query $Query
} else {
    Write-Host "ERROR: Target script not found: $target" -ForegroundColor Red
    exit 1
}
