# F:\AION-ZERO\scripts\AZ-Build-ProjectIndex.ps1
$ErrorActionPreference = "Stop"

# Root + logs
$root   = "F:\AION-ZERO"
$logDir = Join-Path $root "logs"
New-Item -Path $logDir -ItemType Directory -Force | Out-Null

# Load mail helper
. "F:\AION-ZERO\scripts\Send-AOGRLMail.ps1"

# Folders JARVIS/AZ should know about
$folders = @(
    "F:\AION-ZERO",
    "F:\EduConnect",
    "F:\EduConnect\cloud"
) | Where-Object { Test-Path $_ }

# Collect files (code + config)
$items = foreach ($folder in $folders) {
    Get-ChildItem -Path $folder -Recurse -File -Include `
        *.ps1, *.psm1, *.js, *.ts, *.json, *.toml, *.yaml, *.yml 2>$null |
        Select-Object @{
            Name       = "ProjectRoot"; Expression = { $folder }
        }, FullName, Extension, Length, LastWriteTime
}

# Write full index
$indexPath = Join-Path $logDir "project-index.json"
$items | ConvertTo-Json -Depth 4 | Set-Content -Path $indexPath -Encoding UTF8

# Summary object
$summary = [PSCustomObject]@{
    Timestamp    = (Get-Date).ToString("s")
    FileCount    = $items.Count
    TotalBytes   = ($items | Measure-Object Length -Sum).Sum
    ProjectsSeen = ($folders -join ", ")
    IndexPath    = $indexPath
}

$summaryPath = Join-Path $logDir "project-index-summary.json"
$summary | ConvertTo-Json -Depth 3 | Set-Content -Path $summaryPath -Encoding UTF8

# Email you the result
$mb = [Math]::Round($summary.TotalBytes / 1MB, 2)

$body = @"
<h2>AZ Project Index Build Completed</h2>
<p><b>Time:</b> $($summary.Timestamp)</p>
<p><b>Files indexed:</b> $($summary.FileCount)</p>
<p><b>Total size:</b> $mb MB</p>
<p><b>Projects scanned:</b> $($summary.ProjectsSeen)</p>
<p><b>Index file:</b> $($summary.IndexPath)</p>
<p><b>Summary file:</b> $($summaryPath)</p>
"@

Send-AOGRLMail `
    -To "omranahmad@yahoo.com" `
    -Subject "[AZ] Project Index Build" `
    -Body $body `
    -IsHtml
