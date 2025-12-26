# Test-Supabase.ps1
# Simple connectivity test for Supabase using Load-Supabase.ps1

# Load URL + key from environment / .env
$info = & "$PSScriptRoot\Load-Supabase.ps1"

$baseUrl = $info.Url.TrimEnd('/')
$apiKey  = $info.Key

Write-Host "Testing Supabase at: $baseUrl" -ForegroundColor Cyan

$headers = @{
    apikey        = $apiKey
    Authorization = "Bearer $apiKey"
    "Content-Type" = "application/json"
}

# Use a known-good view/table for EduConnect
$uri = "$baseUrl/rest/v1/enrollment_summary?select=*&limit=1"

try {
    $res = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -ErrorAction Stop
    $count = 0
    if ($res) { $count = @($res).Count }
    Write-Host "Supabase connectivity OK at $baseUrl (enrollment_summary, rows=$count)" -ForegroundColor Green
}
catch {
    Write-Host "Error talking to Supabase at $baseUrl" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    throw
}
