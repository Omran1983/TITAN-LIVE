# F:\AION-ZERO\scripts\List-CF-Zones.ps1

$ErrorActionPreference = "Stop"
. "F:\AION-ZERO\scripts\Load-Cloudflare.ps1"

& "F:\AION-ZERO\scripts\Invoke-CFApi.ps1" -Path "/zones" -Method "GET"
