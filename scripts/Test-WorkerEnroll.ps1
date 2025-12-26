# F:\AION-ZERO\scripts\Test-WorkerEnroll.ps1

$ErrorActionPreference = "Stop"

$uri = "https://educonnect-hq-lite.dubsy1983-51e.workers.dev/enroll"

$bodyObj = @{
    full_name = "Worker Form Test"
    email     = "form-test@example.com"
    phone     = "2301234567"
    course    = "AI Workshop"
    source    = "worker-test"
    notes     = "Posted via Cloudflare Worker test script"
}

$bodyJson = $bodyObj | ConvertTo-Json -Depth 5

Write-Host "POST $uri"
Write-Host "Body: $bodyJson"

try {
    $resp = Invoke-WebRequest -Uri $uri -Method Post -Body $bodyJson -ContentType "application/json"
    Write-Host "Status: $($resp.StatusCode)"
    Write-Host "Response body: $($resp.Content)"
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
        Write-Host "Error body from Worker:" -ForegroundColor Yellow
        Write-Host $_.ErrorDetails.Message
    }
}
