# F:\AION-ZERO\scripts\Scan-Secrets.ps1
# Read-only helper: lists any suspicious hardcoded keys/URLs so you can clean manually.

$ErrorActionPreference = "Stop"

$root = "F:\AION-ZERO"

$patterns = @(
    "supabase.co",
    "service_role",
    "anon ",
    "CLOUDFLARE_API_TOKEN",
    "api.cloudflare.com",
    "CF_ACCOUNT_ID",
    "CF_ZONE_ID"
)

Get-ChildItem -Path $root -Recurse -Include *.ps1,*.psm1,*.toml,*.json,*.yaml,*.yml,*.env,*.config |
    Where-Object { -not $_.FullName.ToLower().Contains("env\supabase.secrets") -and -not $_.FullName.ToLower().Contains("env\cloudflare.secrets") } |
    Select-String -Pattern $patterns -SimpleMatch |
    Sort-Object Path, LineNumber |
    Select-Object Path, LineNumber, Line
