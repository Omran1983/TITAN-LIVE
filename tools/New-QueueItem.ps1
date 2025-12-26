param(
  [Parameter(Mandatory)][string]$AZHome,
  [Parameter(Mandatory)][string]$Type,
  [Parameter(Mandatory)][string]$Project,
  [Parameter(Mandatory)][string]$Bot,
  [string]$Name = "",
  [hashtable]$Payload,
  [string]$PayloadJson = "{}"
)
$Queue = Join-Path $AZHome 'bridge\file-queue'
New-Item -ItemType Directory -Force -Path $Queue | Out-Null

$ts = Get-Date -AsUTC -Format 'yyyyMMdd-HHmmss'
$id = ('T-{0}-{1}-{2}-{3}' -f $Type,$Project,($Name -replace '[^\w\-]','' -replace '^\s*$','GEN'),$ts)

$payloadObj = @{}
if ($PSBoundParameters.ContainsKey('Payload')) { $payloadObj = $Payload }
elseif ($PayloadJson) { try { $payloadObj = $PayloadJson | ConvertFrom-Json -ea Stop } catch { $payloadObj = @{} } }

$body = [ordered]@{
  id         = $id
  type       = $Type
  project    = $Project
  bot        = $Bot
  payload    = $payloadObj
  enqueuedAt = (Get-Date -AsUTC -Format s)
}

$path = Join-Path $Queue ($id + '.json')
$body | ConvertTo-Json -Depth 12 | Set-Content -Path $path -Encoding UTF8
$path
