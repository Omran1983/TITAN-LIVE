$proj = "F:\AION-ZERO"
$planOnly = Test-Path "$proj\tweakops\PLAN_ONLY"
if ($planOnly) {
  Write-Host "PLAN-ONLY MODE: Will not call engine."
  Start-Sleep -Seconds 5
  exit 0
}
pwsh -NoProfile -ExecutionPolicy Bypass -File "$proj\tweakops\Start-AutoPatch-Plus.ps1" -ProjectRoot $proj
