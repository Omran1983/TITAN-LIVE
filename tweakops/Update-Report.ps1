param(
  [Parameter(Mandatory=$true)][string]$PatchId,
  [Parameter(Mandatory=$true)][string]$Status,
  [Parameter(Mandatory=$true)][string]$Notes
)
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$pdir = Join-Path $root "patches\$PatchId"
if (!(Test-Path $pdir)) { throw "Patch $PatchId not found" }

# If a report exists, update; else create minimal
$rep = Join-Path $pdir "report.html"
if (!(Test-Path $rep)) {
  @"
<html><body>
<h2>Tweak Report: $PatchId</h2>
<p>Status: <b>$Status</b></p>
<p>Notes: $Notes</p>
</body></html>
"@ | Out-File -Encoding UTF8 $rep
} else {
  $html = Get-Content $rep -Raw
  $html = $html -replace '(Status:\s*<b>).*?(</b>)', "`${1}$Status`${2}"
  $html = $html -replace '(Notes:\s*)[^<]*', "`${1}$Notes"
  $html | Out-File -Encoding UTF8 $rep
}

# Append diff snippet if present
$diff = Join-Path $pdir "diff.patch"
if (Test-Path $diff) {
  Add-Content -Encoding UTF8 $rep "`n<pre>`n$(Get-Content $diff -Raw)`n</pre>`n"
}

Write-Host "Updated report for $PatchId → $Status"
