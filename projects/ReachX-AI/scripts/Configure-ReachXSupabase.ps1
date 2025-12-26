param()

Write-Host "=== ReachX Supabase Configuration ===" -ForegroundColor Cyan

$SupabaseUrl = Read-Host "Enter Supabase URL (e.g. https://abkprecmhitqmmlzxfad.supabase.co)"
$SupabaseKey = Read-Host "Enter Supabase *service_role* key (long JWT-like string)"

if ([string]::IsNullOrWhiteSpace($SupabaseUrl) -or [string]::IsNullOrWhiteSpace($SupabaseKey)) {
    Write-Host "Both URL and service_role key are required." -ForegroundColor Red
    return
}

if ($SupabaseUrl -like "*YOURPROJECT*" -or $SupabaseKey -like "*YOUR_*" -or $SupabaseKey -like "<*") {
    Write-Host "You entered placeholder values. Paste the REAL URL and REAL service_role key from Supabase." -ForegroundColor Red
    return
}

$SupabaseUrl = $SupabaseUrl.TrimEnd("/")

$env:REACHX_SUPABASE_URL         = $SupabaseUrl
$env:REACHX_SUPABASE_SERVICE_KEY = $SupabaseKey.Trim()

Write-Host ""
Write-Host "Testing Supabase auth with the values you just entered..." -ForegroundColor Yellow

$headers = @{
    apikey        = $env:REACHX_SUPABASE_SERVICE_KEY
    Authorization = "Bearer $env:REACHX_SUPABASE_SERVICE_KEY"
}

$testUri = "$env:REACHX_SUPABASE_URL/rest/v1/workers?select=count"
Write-Host "GET $testUri" -ForegroundColor DarkCyan

try {
    $resp = Invoke-RestMethod -Uri $testUri -Headers $headers -Method Get
    Write-Host "Auth OK. Supabase returned:" -ForegroundColor Green
    $resp
}
catch {
    Write-Host "Auth FAILED. Check that you used the correct project URL and the *service_role* key (not anon)." -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor DarkRed
    return
}

Write-Host ""
Write-Host "Environment now set for this session:" -ForegroundColor Cyan
Write-Host "  REACHX_SUPABASE_URL         = $env:REACHX_SUPABASE_URL"
Write-Host "  REACHX_SUPABASE_SERVICE_KEY = [hidden]" -ForegroundColor Cyan
