$secretDir  = "F:\AION-ZERO\secrets"
$configPath = Join-Path $secretDir "educonnect-smtp.json"

if (-not (Test-Path $secretDir)) {
    New-Item -ItemType Directory -Path $secretDir -Force | Out-Null
}

if (Test-Path $configPath) {
    Write-Host "Config already exists:" $configPath -ForegroundColor Yellow
} else {
    $sample = @{
        smtp_host  = "smtp.yourprovider.com"
        smtp_port  = 587
        enable_ssl = $true
        username   = "your-smtp-username"
        password   = "your-smtp-password"
        from_email = "AI Workshop <no-reply@yourdomain.com>"
    } | ConvertTo-Json -Depth 3

    Set-Content -Path $configPath -Value $sample -Encoding UTF8
    Write-Host "Sample SMTP config written to:" $configPath -ForegroundColor Green
    Write-Host "Edit this file and put REAL SMTP credentials before sending emails."
}
