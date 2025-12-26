param()

# Load static config
. "F:\ReachX-AI\config\ReachX-Supabase.ps1"

if (-not $REACHX_SUPABASE_URL -or -not $REACHX_SUPABASE_SERVICE_KEY) {
    throw "ReachX Supabase config is missing URL or KEY. Edit F:\ReachX-AI\config\ReachX-Supabase.ps1"
}

$env:REACHX_SUPABASE_URL         = $REACHX_SUPABASE_URL.TrimEnd("/")
$env:REACHX_SUPABASE_SERVICE_KEY = $REACHX_SUPABASE_SERVICE_KEY.Trim()

Write-Host "ReachX Supabase env set:" -ForegroundColor Cyan
Write-Host "  REACHX_SUPABASE_URL = $env:REACHX_SUPABASE_URL" -ForegroundColor Cyan
Write-Host "  REACHX_SUPABASE_SERVICE_KEY = [hidden]" -ForegroundColor Cyan
