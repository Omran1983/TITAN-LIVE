param([string]$AZHome = "F:\AION-ZERO")
$queue = Join-Path $AZHome "bridge\file-queue"
New-Item -ItemType Directory -Force -Path $queue | Out-Null
$id  = "T-HEALTHCHECK-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss-fff")
$ts  = Get-Date -AsUTC -Format s
$pth = Join-Path $queue ($id + ".json")
'{"id":"'+$id+'","type":"HEALTHCHECK","payload":{"ts":"'+$ts+'"}}' | Set-Content -Path $pth -Encoding UTF8
