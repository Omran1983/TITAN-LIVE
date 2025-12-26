$ErrorActionPreference = "Stop"

$eduRoot    = "F:\EduConnect"
$workerRoot = Join-Path $eduRoot "cloud\hq-lite-worker"
$srcDir     = Join-Path $workerRoot "src"
$indexPath  = Join-Path $srcDir "index.js"
$statusPath = Join-Path $srcDir "status-module.js"

# 1) Paths check
if (-not (Test-Path $workerRoot)) {
    Write-Host "EduConnect Worker root not found: $workerRoot" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $statusPath)) {
    Write-Host "status-module.js not found at $statusPath" -ForegroundColor Red
    exit 1
}

# 2) Restore from the first backup we know you have
$backupPath = Join-Path $srcDir "index.js.bak-20251115-214615"
if (-not (Test-Path $backupPath)) {
    Write-Host "Expected backup not found: $backupPath" -ForegroundColor Red
    exit 1
}

Copy-Item $backupPath $indexPath -Force
Write-Host "Restored index.js from backup: $backupPath" -ForegroundColor Yellow

# 3) Reload restored index.js
$lines = Get-Content $indexPath

# 3a) Ensure import for handleStatusRequest
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
    Write-Host "handleStatusRequest import already present in restored file." -ForegroundColor DarkYellow
}

# 3b) Inject /status check AFTER first 'new URL(' line, reusing existing url
$newLines = @()
$injected = $false
$urlIndex = -1

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $newLines += $line

    if (-not $injected -and $line -match 'new\s+URL\(') {
        $urlIndex = $i

        $indentMatch = [regex]::Match($line, '^(\s*)')
        $indent = $indentMatch.Groups[1].Value

        $routeBlock = @()
        $routeBlock += "${indent}if (url.pathname === ""/status"") {"
        $routeBlock += "${indent}  return handleStatusRequest(env);"
        $routeBlock += "${indent}}"

        $newLines += $routeBlock
        $injected = $true

        Write-Host "Injected /status block after first 'new URL(' line." -ForegroundColor Green
    }
}

if (-not $injected) {
    Write-Host "Could not find a line with 'new URL(' to inject after." -ForegroundColor Red
    exit 1
}

Set-Content -Path $indexPath -Value $newLines -Encoding UTF8

# 4) Log build
$eduJournal = Join-Path "F:\AION-ZERO\logs" "educonnect-build-journal.md"
$entry = @"
## EduConnect Build (Status Route Clean Inject) $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Files updated:
- $indexPath

Backup used:
- $backupPath

Notes:
- Restored original index.js from backup.
- Injected /status route AFTER existing 'const url = new URL(...)' using handleStatusRequest(env).
"@

Add-Content -Path $eduJournal -Value $entry

Write-Host "index.js patched cleanly with /status block." -ForegroundColor Green

# 5) Redeploy Worker
Write-Host "Deploying Worker via AZ-Deploy-EduConnectWorker.ps1..." -ForegroundColor Cyan
$deployScript = "F:\AION-ZERO\scripts\AZ-Deploy-EduConnectWorker.ps1"
if (Test-Path $deployScript) {
    & $deployScript
} else {
    Write-Host "Deploy script not found at $deployScript" -ForegroundColor Red
    exit 1
}

# 6) Test /status
Write-Host "Testing /status via Test-EduConnectStatus.ps1..." -ForegroundColor Cyan
$testScript = "F:\AION-ZERO\scripts\Test-EduConnectStatus.ps1"
if (Test-Path $testScript) {
    & $testScript
} else {
    Write-Host "Test script not found at $testScript" -ForegroundColor Red
}
