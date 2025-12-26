# F:\AION-ZERO\scripts\Test-Cloudflare.ps1

$ErrorActionPreference = "Stop"

. "F:\AION-ZERO\scripts\Load-Cloudflare.ps1"

$uri = "https://api.cloudflare.com/client/v4/user/tokens/verify"

$response = Invoke-RestMethod -Uri $uri -Headers $CFHeaders -Method Get

$response | ConvertTo-Json -Depth 5
