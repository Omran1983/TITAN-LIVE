param(
    [switch]$IncludeWarm,
    [switch]$IncludeCold
)

$ErrorActionPreference = "Stop"

# Base paths
$InfraDir     = "F:\ReachX-AI\infra"
$OutreachRoot = "F:\ReachX-AI\outreach"

Write-Host ""
Write-Host "==================================" 
Write-Host " REACHX - OUTREACH CYCLE (ONE-SHOT)" 
Write-Host "==================================" 
Write-Host ""

if (-not (Test-Path $InfraDir)) {
    Write-Host ("ERROR: Infra directory not found: {0}" -f $InfraDir)
    return
}

Set-Location $InfraDir

# --------------------------------------
# Step 1 - Export leads to CSV
# --------------------------------------
Write-Host "Step 1/3 - Exporting leads to CSV..."

$exportScript = Join-Path $InfraDir "Export-ReachXLeads.ps1"
if (-not (Test-Path $exportScript)) {
    Write-Host ("ERROR: Export script not found at {0}" -f $exportScript)
    return
}

if ($IncludeWarm -and $IncludeCold) {
    Write-Host "  Using flags: -IncludeWarm -IncludeCold"
    & $exportScript -IncludeWarm -IncludeCold
}
elseif ($IncludeWarm) {
    Write-Host "  Using flags: -IncludeWarm"
    & $exportScript -IncludeWarm
}
elseif ($IncludeCold) {
    Write-Host "  Using flags: -IncludeCold"
    & $exportScript -IncludeCold
}
else {
    Write-Host "  Using flags: (none - HOT only)"
    & $exportScript
}

Write-Host ""

# --------------------------------------
# Step 2 - Generate email drafts
# --------------------------------------
Write-Host "Step 2/3 - Generating email drafts..."

$generateScript = Join-Path $InfraDir "Generate-ReachXEmails.ps1"
if (-not (Test-Path $generateScript)) {
    Write-Host ("ERROR: Generate script not found at {0}" -f $generateScript)
    return
}

& $generateScript

Write-Host ""

# --------------------------------------
# Step 3 - Open latest outreach batch folder
# --------------------------------------
Write-Host "Step 3/3 - Opening latest outreach batch folder..."

if (-not (Test-Path $OutreachRoot)) {
    Write-Host ("WARNING: Outreach root not found: {0}" -f $OutreachRoot)
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
Write-Host "ReachX outreach cycle complete."
