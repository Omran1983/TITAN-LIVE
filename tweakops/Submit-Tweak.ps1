param(
  [Parameter(Mandatory=$true)][string]$Client,
  [Parameter(Mandatory=$true)][string]$Intent,
  [Parameter(Mandatory=$false)][string]$TargetFiles
)

$root  = Split-Path -Parent $MyInvocation.MyCommand.Path
$queue = Join-Path $root "queue"
New-Item -ItemType Directory -Force -Path $queue | Out-Null

$targets = @()
if (-not [string]::IsNullOrWhiteSpace($TargetFiles)) {
  $targets = $TargetFiles -split '\s*,\s*' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}

$id = (Get-Date -Format 'yyyyMMdd_HHmmss')
$payload = [ordered]@{
  id           = $id
  client       = $Client
  intent       = $Intent
  target_files = $targets
}

($payload | ConvertTo-Json -Depth 5) | Set-Content -Path (Join-Path $queue "$id.json") -Encoding UTF8 -NoNewline
Write-Host "Queued tweak $id"
