$ErrorActionPreference = "Stop"

$logDir = "F:\AION-ZERO\logs"

if (-not (Test-Path $logDir)) {
    Write-Host "Log directory not found: $logDir" -ForegroundColor Red
    exit 1
}

Write-Host "=== AZ / JARVIS PROGRESS SNAPSHOT ===" -ForegroundColor Cyan
Write-Host "Log directory: $logDir"
Write-Host ""

$summaryPath = Join-Path $logDir "project-index-summary.json"
if (Test-Path $summaryPath) {
    Write-Host ">> Summary (project-index-summary.json)" -ForegroundColor Yellow
    $summary = Get-Content $summaryPath -Raw | ConvertFrom-Json

    "Time       : {0}" -f $summary.Timestamp
    "Projects   : {0}" -f $summary.Projects
    "FileCount  : {0}" -f $summary.FileCount
    "IndexPath  : {0}" -f $summary.IndexPath
    ""
} else {
    Write-Host "No project-index-summary.json found." -ForegroundColor DarkYellow
    Write-Host ""
}

Write-Host ">> Latest snapshots" -ForegroundColor Yellow
$snapshots = Get-ChildItem $logDir -Filter "project-index-snapshot-*.json" -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending

if ($snapshots) {
    $snapshots | Select-Object -First 5 |
        ForEach-Object {
            "{0:yyyy-MM-dd HH:mm:ss}  {1}" -f $_.LastWriteTime, $_.FullName
        }
} else {
    Write-Host "No snapshot files found." -ForegroundColor DarkYellow
}
Write-Host ""

$journalPath = Join-Path $logDir "AZ-build-journal.md"
Write-Host ">> Night Build journal (last 20 lines)" -ForegroundColor Yellow
if (Test-Path $journalPath) {
    Get-Content $journalPath -Tail 20
} else {
    Write-Host "No AZ-build-journal.md found." -ForegroundColor DarkYellow
}
Write-Host ""

$okaJournalPath = Join-Path $logDir "okasina-build-journal.md"
Write-Host ">> OKASINA build journal (last 20 lines)" -ForegroundColor Yellow
if (Test-Path $okaJournalPath) {
    Get-Content $okaJournalPath -Tail 20
} else {
    Write-Host "No okasina-build-journal.md found." -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "=== END SNAPSHOT ===" -ForegroundColor Cyan
