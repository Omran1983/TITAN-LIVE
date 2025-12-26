param(
    [string]$PythonExe = "C:\Python313\python.exe"
)

$ErrorActionPreference = "Stop"

Write-Host "=== ReachX Agent Harvest Pipeline ===" -ForegroundColor Cyan

$root     = Split-Path $PSScriptRoot -Parent
$scrapers = Join-Path $root "scrapers"
$scripts  = $PSScriptRoot

function Run-Step {
    param(
        [string]$Name,
        [scriptblock]$Action
    )
    Write-Host ">>> $Name ..." -ForegroundColor Yellow
    & $Action
    if ($LASTEXITCODE -ne 0) {
        throw "Step '$Name' failed with exit code $LASTEXITCODE"
    }
    Write-Host (">>> {0}: OK" -f $Name) -ForegroundColor Green
}

Run-Step -Name "1/3 Harvest Mauritius IFC employers" -Action {
    & $PythonExe (Join-Path $scrapers "agent_harvest.py")
}

Run-Step -Name "2/3 Ingest employers into Supabase" -Action {
    & $PythonExe (Join-Path $scrapers "incoming_ingest.py")
}

Run-Step -Name "3/3 Refresh ReachX UI" -Action {
    & (Join-Path $scripts "ReachX-Refresh-All.ps1")
}

Write-Host "=== ReachX Agent Harvest Pipeline: DONE ===" -ForegroundColor Green
