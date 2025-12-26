# F:\ReachX-AI\scripts\ReachX-Generate-SupabaseConfig.ps1

$ErrorActionPreference = "Stop"

$root    = "F:\ReachX-AI"
$envFile = Join-Path $root ".env"
$uiRoot  = Join-Path $root "infra\ReachX-Workers-UI-v1"
$outFile = Join-Path $uiRoot "supabase-config.js"

if (-not (Test-Path $envFile)) {
    throw "Env file not found at $envFile"
}

# Parse .env → hashtable
$envMap = @{}
Get-Content $envFile |
    Where-Object { $_ -and -not $_.StartsWith("#") } |
    ForEach-Object {
        $parts = $_ -split "=", 2
        if ($parts.Count -eq 2) {
            $name  = $parts[0].Trim()
            $value = $parts[1].Trim()
            if ($name) { $envMap[$name] = $value }
        }
    }

$sbUrl = $envMap["REACHX_SUPABASE_URL"]
$sbKey = $envMap["REACHX_SUPABASE_ANON_KEY"]

if (-not $sbUrl -or -not $sbKey) {
    throw "REACHX_SUPABASE_URL or REACHX_SUPABASE_ANON_KEY missing in .env"
}

if (-not (Test-Path $uiRoot)) {
    throw "UI root not found at $uiRoot"
}

@"
window.REACHX_SUPABASE_URL      = '$sbUrl';
window.REACHX_SUPABASE_ANON_KEY = '$sbKey';
"@ | Set-Content -Path $outFile -Encoding UTF8

Write-Host "Generated supabase-config.js at $outFile"
