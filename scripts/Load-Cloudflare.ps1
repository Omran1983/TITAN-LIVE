# F:\AION-ZERO\scripts\Load-Cloudflare.ps1

$secretsPath = "F:\AION-ZERO\env\cloudflare.secrets"

if (-not (Test-Path $secretsPath)) {
    throw "cloudflare.secrets not found at $secretsPath"
}

$C = @{}
Get-Content $secretsPath | ForEach-Object {
    if ($_ -match "^\s*([^#=\s]+)\s*=\s*(.+?)\s*$") {
        $C[$matches[1]] = $matches[2].Trim('"').Trim("'").Trim()
    }
}

$global:CF_API_TOKEN       = $C["CLOUDFLARE_API_TOKEN"]
$global:CF_ACCOUNT_ID      = $C["CLOUDFLARE_ACCOUNT_ID"]
$global:CF_ZONE_ID_JARVIS  = $C["CLOUDFLARE_ZONE_ID_JARVIS"]

if (-not $CF_API_TOKEN -or $CF_API_TOKEN.Length -lt 20) {
    throw "CLOUDFLARE_API_TOKEN missing or too short."
}

$global:CFHeaders = @{
    "Authorization" = "Bearer $CF_API_TOKEN"
    "Content-Type"  = "application/json"
}
