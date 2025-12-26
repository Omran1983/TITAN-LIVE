$ErrorActionPreference = "Stop"

$root   = "F:\AION-ZERO"
$logDir = Join-Path $root "logs"
New-Item -Path $logDir -ItemType Directory -Force | Out-Null

$projects = @(
    @{ Name = "AION-ZERO";        Root = "F:\AION-ZERO" },
    @{ Name = "EduConnect";       Root = "F:\EduConnect" },
    @{ Name = "EduConnect Cloud"; Root = "F:\EduConnect\cloud" },
    @{ Name = "OKASINA";          Root = "C:\Users\ICL  ZAMBIA\Desktop\okasina-fashion-store-vite" }
) | Where-Object { Test-Path $_.Root }

$filesIndexed = New-Object System.Collections.Generic.List[object]
$docsCreated  = New-Object System.Collections.Generic.List[string]

foreach ($p in $projects) {
    $rootPath = $p.Root

    Get-ChildItem -Path $rootPath -Recurse -File -Include `
        *.ps1, *.psm1, *.js, *.ts, *.jsx, *.tsx, *.json, *.toml, *.yaml, *.yml 2>$null |
        ForEach-Object {
            $filesIndexed.Add([PSCustomObject]@{
                Project   = $p.Name
                FullName  = $_.FullName
                Extension = $_.Extension
                Length    = $_.Length
                LastWrite = $_.LastWriteTime
            })
        }

    $docsDir = Join-Path $rootPath "docs"
    New-Item -Path $docsDir -ItemType Directory -Force | Out-Null

    $nameSlug = $p.Name -replace ' ', '-'
    $archPath = Join-Path $docsDir ("ARCHITECTURE-{0}.md" -f $nameSlug)

    if (-not (Test-Path $archPath)) {
$archContent = @"
# Architecture – $($p.Name)

- Created: $(Get-Date -Format "yyyy-MM-dd HH:mm")
- Owner: Omran / JARVIS-AZ

## Overview

(Write a 1–2 paragraph overview here.)

## Key Components

- [ ] Main services / scripts
- [ ] Where state is stored (Supabase / local / etc.)

## Next Ideas

- [ ] What JARVIS/AZ should automate next
"@
        Set-Content -Path $archPath -Value $archContent -Encoding UTF8
        $docsCreated.Add($archPath)
    }
}

$indexPath = Join-Path $logDir "project-index.json"
$filesIndexed | ConvertTo-Json -Depth 4 | Set-Content -Path $indexPath -Encoding UTF8

$summary = [PSCustomObject]@{
    Timestamp   = (Get-Date).ToString("s")
    Projects    = ($projects.Name -join ", ")
    FileCount   = $filesIndexed.Count
    DocsCreated = $docsCreated
    IndexPath   = $indexPath
}

$summaryPath = Join-Path $logDir "project-index-summary.json"
$summary | ConvertTo-Json -Depth 4 | Set-Content -Path $summaryPath -Encoding UTF8

$snapshotName = "project-index-snapshot-{0:yyyyMMdd-HHmmss}.json" -f (Get-Date)
$snapshotPath = Join-Path $logDir $snapshotName
$filesIndexed | ConvertTo-Json -Depth 4 | Set-Content -Path $snapshotPath -Encoding UTF8

$journalPath = Join-Path $logDir "AZ-build-journal.md"
$journalEntry = @"
## Night Build $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Projects: $($summary.Projects)
Files indexed: $($summary.FileCount)
Snapshot: $snapshotPath

"@
Add-Content -Path $journalPath -Value $journalEntry

Write-Host "Night build completed. Files indexed: $($summary.FileCount)" -ForegroundColor Cyan
Write-Host "Snapshot: $snapshotPath" -ForegroundColor Cyan
