$ErrorActionPreference = "Stop"

$eduRoot    = "F:\EduConnect"
$workerRoot = Join-Path $eduRoot "cloud\hq-lite-worker"
$srcDir     = Join-Path $workerRoot "src"
$indexPath  = Join-Path $srcDir "index.js"
$statusPath = Join-Path $srcDir "status-module.js"

if (-not (Test-Path $workerRoot)) {
    Write-Host "EduConnect Worker root not found: $workerRoot" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $indexPath)) {
    Write-Host "index.js not found at $indexPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $statusPath)) {
    Write-Host "status-module.js not found at $statusPath" -ForegroundColor Red
    exit 1
}

$timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = "$indexPath.forcebak-$timestamp"

Copy-Item $indexPath $backupPath -Force
Write-Host "Force-backup created: $backupPath" -ForegroundColor Yellow

# --- ensure import line exists ---
$lines = Get-Content $indexPath

if (-not ($lines -match 'handleStatusRequest')) {
    $importLine = 'import { handleStatusRequest } from "./status-module";'

    $insertIndex = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*import\s') {
            $insertIndex = $i + 1
        }
    }

    if ($insertIndex -eq 0) {
        $lines = ,$importLine + $lines
    } else {
        $before = $lines[0..($insertIndex-1)]
        $after  = $lines[$insertIndex..($lines.Count-1)]
        $lines  = $before + $importLine + $after
    }

    Write-Host "Added handleStatusRequest import." -ForegroundColor Green
} else {
    Write-Host "Import for handleStatusRequest already present." -ForegroundColor DarkYellow
}

# --- force-inject /status route at top of fetch() ---
$newLines = @()
$injected = $false

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]

    if (-not $injected -and $line -match '(async\s+)?fetch\s*\(([^)]*)\)') {
        $newLines += $line

        $paramList = $matches[2].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

        if ($paramList.Count -ge 2) {
            $reqVar = $paramList[0]
            $envVar = $paramList[1]
        } else {
            $reqVar = "request"
            $envVar = "env"
        }

        $indentMatch = [regex]::Match($line, '^(\s*)')
        $indent = $indentMatch.Groups[1].Value + '    '

        $routeBlock = @()
        $routeBlock += "${indent}const url = new URL(${reqVar}.url);"
        $routeBlock += "${indent}if (url.pathname === ""/status"") {"
        $routeBlock += "${indent}    return handleStatusRequest(${envVar});"
        $routeBlock += "${indent}}"

        $newLines += $routeBlock
        $injected = $true

        Write-Host "Force-injected /status route using request var '$reqVar' and env var '$envVar'." -ForegroundColor Green
    } else {
        $newLines += $line
    }
}

if (-not $injected) {
    Write-Host "Could not locate fetch() handler to inject /status route." -ForegroundColor Red
    exit 1
}

Set-Content -Path $indexPath -Value $newLines -Encoding UTF8

$eduJournal = Join-Path "F:\AION-ZERO\logs" "educonnect-build-journal.md"
$entry = @"
## EduConnect Build (Status Route Force-Inject) $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Files updated:
- $indexPath

Backup:
- $backupPath

Notes:
- Force-injected /status route at top of fetch() to call handleStatusRequest(env).
"@

Add-Content -Path $eduJournal -Value $entry

Write-Host "EduConnect /status route force-injected in index.js" -ForegroundColor Green
