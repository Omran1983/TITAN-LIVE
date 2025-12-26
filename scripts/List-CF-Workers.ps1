# F:\AION-ZERO\scripts\List-CF-Workers.ps1

$ErrorActionPreference = "Stop"
. "F:\AION-ZERO\scripts\Load-Cloudflare.ps1"

if (-not $CF_ACCOUNT_ID) {
    throw "CF_ACCOUNT_ID missing in cloudflare.secrets"
}

& "F:\AION-ZERO\scripts\Invoke-CFApi.ps1" -Path "/accounts/$CF_ACCOUNT_ID/workers/scripts" -Method "GET"
