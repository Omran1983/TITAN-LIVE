# F:\AION-ZERO\scripts\Test-EduEnroll.ps1

$ErrorActionPreference = "Stop"

. "F:\AION-ZERO\scripts\Load-Supabase.ps1"

$serviceKey = $env:SUPABASE_SERVICE_ROLE_KEY
if (-not $serviceKey) {
    throw "SUPABASE_SERVICE_ROLE_KEY not found in environment."
}

$uri = "$SBURL/rest/v1/edu_enrollments"

$headers = @{
    "apikey"        = $serviceKey
    "Authorization" = "Bearer $serviceKey"
    "Content-Type"  = "application/json"
    "Prefer"        = "return=representation"
}

$bodyObj = @{
    full_name = "Worker Test User"
    notes     = "Inserted from PowerShell test"
    course    = "AI Workshop"
    phone     = "2300000000"
    source    = "ps-test"
    email     = "worker-test@example.com"
}

$bodyJson = $bodyObj | ConvertTo-Json -Depth 5

Write-Host "POST $uri"
Write-Host "Body: $bodyJson"

try {
    $resp = Invoke-WebRequest -Uri $uri -Method Post -Headers $headers -Body $bodyJson
    Write-Host "Status: $($resp.StatusCode)"
    Write-Host "Response body: $($resp.Content)"
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red

    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
        Write-Host "Error body from Supabase:" -ForegroundColor Yellow
        Write-Host $_.ErrorDetails.Message
    }
    elseif ($_.Exception.Response -and $_.Exception.Response.Content) {
        Write-Host "Error body from Supabase:" -ForegroundColor Yellow
        Write-Host $_.Exception.Response.Content
    }
}
