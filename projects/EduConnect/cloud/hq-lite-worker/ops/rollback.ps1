param(
  [ValidateSet("restore","save")]
  [string]$Action = "restore"
)

$proj = "F:\EduConnect\cloud\hq-lite-worker"
$snap = "F:\EduConnect\out\hq-lite-snapshot"
$wtoml = Join-Path $proj "wrangler.toml"
$wgood = Join-Path $snap "wrangler.good.toml"
$js    = Join-Path $proj "src\index.js"
$jgood = Join-Path $snap "index.good.js"

if ($Action -eq "restore") {
  if (!(Test-Path $wgood) -or !(Test-Path $jgood)) { throw "Snapshot is missing. Run with -Action save first." }
  Copy-Item $wgood $wtoml -Force
  Copy-Item $jgood $js    -Force
  Set-Location $proj
  wrangler deploy --name educonnect-hq-lite
  Write-Host "✅ Restored snapshot and redeployed." -ForegroundColor Green
}
elseif ($Action -eq "save") {
  if (!(Test-Path $wtoml) -or !(Test-Path $js)) { throw "Project files missing." }
  New-Item -ItemType Directory -Force $snap | Out-Null
  Copy-Item $wtoml $wgood -Force
  Copy-Item $js    $jgood -Force
  $ver = wrangler --version
  "wrangler=$ver" | Set-Content (Join-Path $snap "VERSIONS.txt")
  "STATUS=2885b21636b34375b6d12ae42f703993`nAUDIT=2a458f87826b44088f1071e57f3524d2" |
    Set-Content (Join-Path $snap "KV_BINDINGS.txt")
  Write-Host "💾 Snapshot updated." -ForegroundColor Cyan
}
