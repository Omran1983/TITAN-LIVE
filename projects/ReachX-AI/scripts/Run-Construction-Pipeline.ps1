param(
    [switch]$SkipRefresh
)

$ErrorActionPreference = "Stop"

Write-Host "=== ReachX Construction Pipeline ===" -ForegroundColor Cyan
Write-Host "Root: F:\ReachX-AI" -ForegroundColor DarkGray

$root = "F:\ReachX-AI"

# 🔒 Force the exact Python that has requests + supabase
$python = "C:\Python313\python.exe"   # <-- change if your previous test printed a different path

function Run-Step {
    param(
        [string]$Name,
        [scriptblock]$Action
    )
    Write-Host ""
    Write-Host ">>> $Name..." -ForegroundColor Cyan
    try {
        $global:LASTEXITCODE = 0
        & $Action

        if ($LASTEXITCODE -ne 0) {
            throw "Step '$Name' failed with exit code $LASTEXITCODE"
        }

        Write-Host ">>> ${Name}: OK" -ForegroundColor Green
    }
    catch {
        Write-Host ">>> ${Name}: FAILED" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        throw
    }
}

# 1) Scrape construction / CBRD sources
Run-Step -Name "1/4 Scrape construction data (construction_scraper.py)" -Action {
    Push-Location $root
    & $python ".\scrapers\construction_scraper.py"
    Pop-Location
}

# 2) Dedupe / normalise construction companies
Run-Step -Name "2/4 Dedupe construction companies (dedupe_construction.py)" -Action {
    Push-Location $root
    & $python ".\scrapers\dedupe_construction.py"
    Pop-Location
}

# 3) Enrich (email / website etc.)
Run-Step -Name "3/4 Enrich construction companies (enrich_construction.py)" -Action {
    Push-Location $root
    & $python ".\scrapers\enrich_construction.py"
    Pop-Location
}

# 4) Refresh ReachX data / UI snapshot
if (-not $SkipRefresh) {
    $refreshScript = Join-Path $root "scripts\ReachX-Refresh-All.ps1"
    if (Test-Path $refreshScript) {
        Run-Step -Name "4/4 ReachX-Refresh-All.ps1" -Action {
            & $refreshScript
        }
    }
    else {
        Write-Host "[WARN] ReachX-Refresh-All.ps1 not found, skipping refresh step." -ForegroundColor Yellow
    }
}
else {
    Write-Host "[INFO] SkipRefresh flag set, not calling ReachX-Refresh-All.ps1" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Pipeline complete ===" -ForegroundColor Cyan
