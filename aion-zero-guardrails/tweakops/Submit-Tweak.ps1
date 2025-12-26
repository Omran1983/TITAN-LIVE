param(
  [Parameter(Mandatory=$true)][string]$Client,
  [Parameter(Mandatory=$true)][string]$Intent,
  [Parameter(Mandatory=$true)][string[]]$TargetFiles
)
$now = Get-Date -Format 'yyyyMMdd_HHmmss'
$req = @{
  id = "$now"
  client = $Client
  intent = $Intent
  target_files = $TargetFiles
}
$dir = Join-Path $PSScriptRoot "queue"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
($req | ConvertTo-Json -Depth 5) | Out-File -Encoding UTF8 -FilePath (Join-Path $dir "$now.json")
Write-Host "Queued tweak request $now for $Client"
