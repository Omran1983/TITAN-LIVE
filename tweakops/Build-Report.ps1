param([Parameter(Mandatory=$true)][string]$PatchId)
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$pdir = Join-Path $root "patches\$PatchId"
if (!(Test-Path $pdir)) { throw "Patch $PatchId not found" }
$rep = Join-Path $pdir "report.html"
if (!(Test-Path $rep)) { throw "No report.html for $PatchId" }
Write-Host "Report at $rep"
