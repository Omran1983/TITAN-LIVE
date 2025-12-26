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
$backupPath = "$indexPath.bak-$timestamp"

Copy-Item $indexPath $backupPath -Force
Write-Host "Backup created: $backupPath" -ForegroundColor Yellow

# Read current index.js
$lines = Get-Content $indexPath

# 1) Ensure import line exists
if (-not ($lines -match 'handleStatusRequest')) {
    $importLine = 'import { handleStatusRequest } from "./status-module";'

    $insertIndex = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*import\s') {
            $insertIndex = $i + 1
        }
    }

    if ($insertIndex -eq 0) {
        # No import lines found, put at very top
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

# 2) Inject /status route inside fetch, if not present
if (-not ($lines -match '/status')) {
    $newLines = @()
    $injected = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $newLines += $line

        if (-not $injected -and $line -match 'async\s+fetch\s*\(([^)]*)\)') {
            $paramList = $matches[1].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

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
            $routeBlock += ("{0}const url = new URL({1}.url);" -f $indent, $reqVar)
            $routeBlock += ("{0}if (url.pathname === ""/status"") { " -f $indent)
            $routeBlock += ("{0}    return handleStatusRequest({1});" -f $indent, $envVar)
            $routeBlock += ("{0}}" -f $indent)

            $newLines += $routeBlock
            $injected = $true
            Write-Host "Injected /status route using request var '$reqVar' and env var '$envVar'." -ForegroundColor Green
        }
    }

    $lines = $newLines
} else {
    Write-Host "A /status route already seems to exist in index.js, skipping injection." -ForegroundColor DarkYellow
}

Set-Content -Path $indexPath -Value $lines -Encoding UTF8

# Log build
$logDir     = "F:\AION-ZERO\logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$eduJournal = Join-Path $logDir "educonnect-build-journal.md"

$entry = @"
## EduConnect Build (Status Route Wiring) $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Files updated:
- $indexPath

Backup:
- $backupPath

Notes:
- Imported handleStatusRequest from status-module.js.
- Wired /status route inside fetch() to return JSON status.
"@

Add-Content -Path $eduJournal -Value $entry

Write-Host "EduConnect /status route wired in index.js" -ForegroundColor Green
