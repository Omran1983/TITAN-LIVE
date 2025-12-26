# EduConnect-Autopilot.ps1
# - Load EduConnect project env
# - Skip reserved test domains (@example.com)
# - Test Supabase connectivity
# - Send all queued EduConnect emails

Write-Host "=== EduConnect Autopilot $(Get-Date -Format o) ===" -ForegroundColor Cyan

# 1) Ensure EduConnect env is loaded
. 'F:\tweakops\Use-ProjectEnv.ps1' -Project educonnect
Write-Host "EduConnect env loaded." -ForegroundColor Cyan

# 2) Load Supabase URL + key (for cleanup step)
$supabaseInfo = & "$PSScriptRoot\Load-Supabase.ps1"
$sbUrl = $supabaseInfo.Url.TrimEnd('/')
$sbKey = $supabaseInfo.Key

$headers = @{
    apikey        = $sbKey
    Authorization = "Bearer $sbKey"
    "Content-Type" = "application/json"
}

# 3) Auto-skip any queued *@example.com test emails (reserved domain)
try {
    $body = @{
        status  = 'skipped_reserved'
        error   = 'Skipped: reserved test domain (@example.com)'
        sent_at = (Get-Date).ToString("o")
    } | ConvertTo-Json

    $uri = "$sbUrl/rest/v1/email_log?to_email=like.*@example.com&status=eq.queued"
    Write-Host "Cleaning reserved-domain (@example.com) queued emails at: $uri" -ForegroundColor Yellow

    Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body $body | Out-Null
    Write-Host "Reserved-domain (@example.com) emails (if any) marked as skipped_reserved." -ForegroundColor Yellow
}
catch {
    Write-Host "Warning: error while skipping reserved-domain emails: $($_.Exception.Message)" -ForegroundColor Red
}

# 4) Test Supabase connectivity
try {
    & "$PSScriptRoot\Test-Supabase.ps1"
}
catch {
    Write-Host "Supabase test failed; aborting EduConnect-Autopilot run." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# 5) Send queued EduConnect emails
try {
    & "$PSScriptRoot\Send-EduconnectQueuedEmails.ps1"
}
catch {
    Write-Host "Error while sending queued emails:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host "=== EduConnect Autopilot run complete ===" -ForegroundColor Green
