# Minimal daemon: classifies and creates a placeholder diff & report
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$queue = Join-Path $root "queue"
$patches = Join-Path $root "patches"
New-Item -ItemType Directory -Force -Path $queue, $patches | Out-Null

function New-Report($id, $status, $notes) {
  $pdir = Join-Path $patches $id
  New-Item -ItemType Directory -Force -Path $pdir | Out-Null
  @"
<html><body>
<h2>Tweak Report: $id</h2>
<p>Status: <b>$status</b></p>
<p>Notes: $notes</p>
</body></html>
"@ | Out-File -Encoding UTF8 (Join-Path $pdir "report.html")
}

Write-Host "TweakOps daemon watching $queue ... Ctrl+C to stop."
while ($true) {
  Get-ChildItem $queue -Filter *.json | ForEach-Object {
    $req = Get-Content $_.FullName -Raw | ConvertFrom-Json
    $id = $req.id
    $pdir = Join-Path $patches $id
    New-Item -ItemType Directory -Force -Path $pdir | Out-Null
    "INTENT: $($req.intent)" | Out-File (Join-Path $pdir "plan.md")
    # Placeholder diff
    @"
--- a/${($req.target_files[0])}
+++ b/${($req.target_files[0])}
@@ -1,1 +1,1 @@
-/* TODO old */
+/* TODO patched by TweakOps ($id) */
"@ | Out-File (Join-Path $pdir "diff.patch")
    New-Report $id "SIMULATED" "Replace with real patch engine + tests + canary."
    Remove-Item $_.FullName -Force
    Write-Host "Processed $id"
  }
  Start-Sleep -Seconds 3
}
