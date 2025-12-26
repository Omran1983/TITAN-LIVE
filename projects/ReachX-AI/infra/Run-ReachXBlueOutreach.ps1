param(
    [int]$Top = 50,
    [string]$Sector,
    [string]$Location
)

$ErrorActionPreference = "Stop"

$InfraDir      = "F:\ReachX-AI\infra"
$OutreachRoot  = "F:\ReachX-AI\outreach-employers"

Write-Host ""
Write-Host "====================================="
Write-Host " REACHX-BLUE — OUTREACH CYCLE (ONE) "
Write-Host "====================================="
Write-Host ""

if (-not (Test-Path $InfraDir)) {
    Write-Host ("ERROR: Infra directory not found: {0}" -f $InfraDir)
    return
}

Set-Location $InfraDir

# Step 1 — Export employers
Write-Host "Step 1/3 - Exporting employers to CSV..."

$exportScript = Join-Path $InfraDir "Export-ReachXEmployers.ps1"
if (-not (Test-Path $exportScript)) {
    Write-Host ("ERROR: Export script not found at {0}" -f $exportScript)
    return
}

# Proper splatting (no argument array)
$exportParams = @{ Top = $Top }
if ($Sector)   { $exportParams.Sector   = $Sector }
if ($Location) { $exportParams.Location = $Location }

Write-Host ("  Params: Top={0}{1}{2}" -f `
    $Top, `
    ($(if ($Sector)   { ", Sector=$Sector"   } else { "" })), `
    ($(if ($Location) { ", Location=$Location" } else { "" })))

& $exportScript @exportParams

Write-Host ""

# Step 2 — Generate outreach drafts
Write-Host "Step 2/3 - Generating outreach drafts..."

$generateScript = Join-Path $InfraDir "Generate-ReachXBlueOutreach.ps1"
if (-not (Test-Path $generateScript)) {
    Write-Host ("ERROR: Generate script not found at {0}" -f $generateScript)
    return
}

& $generateScript

Write-Host ""

# Step 3 — Open latest outreach batch folder
Write-Host "Step 3/3 - Opening latest outreach batch folder..."

if (-not (Test-Path $OutreachRoot)) {
    Write-Host ("WARNING: Outreach-employers root not found: {0}" -f $OutreachRoot)
    Write-Host "No folder will be opened."
    return
}

$latestBatch = Get-ChildItem -Path $OutreachRoot -Directory -Filter "batch-*" |
               Sort-Object LastWriteTime -Descending |
               Select-Object -First 1

if (-not $latestBatch) {
    Write-Host ("WARNING: No batch-* folders found in {0}" -f $OutreachRoot)
    return
}

$batchPath = $latestBatch.FullName
Write-Host ("Latest batch folder: {0}" -f $batchPath)

Start-Process $batchPath

Write-Host ""
Write-Host "ReachX-Blue outreach cycle complete."
