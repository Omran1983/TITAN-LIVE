$SupabaseUrl     = "https://drnqpbyptyyuacmrvdrr.supabase.co"
$serviceKeyFile  = "F:\AION-ZERO\secrets\educonnect-service-role-key.txt"
$smtpConfigFile  = "F:\AION-ZERO\secrets\educonnect-smtp.json"

if (-not (Test-Path $serviceKeyFile)) {
    Write-Host "[ERROR] Service role key file not found: $serviceKeyFile" -ForegroundColor Red
    return
}
if (-not (Test-Path $smtpConfigFile)) {
    Write-Host "[ERROR] SMTP config file not found: $smtpConfigFile" -ForegroundColor Red
    return
}

$SupabaseKey = (Get-Content $serviceKeyFile -Raw).Trim()
if ([string]::IsNullOrWhiteSpace($SupabaseKey)) {
    Write-Host "[ERROR] Service role key file is empty." -ForegroundColor Red
    return
}

$smtpConf = Get-Content $smtpConfigFile -Raw | ConvertFrom-Json

$headers = @{
    apikey         = $SupabaseKey
    Authorization  = "Bearer $SupabaseKey"
    "Content-Type" = "application/json"
}

# 1) Get queued emails
$uri = "$SupabaseUrl/rest/v1/email_log?select=*&status=eq.queued&order=created_at.asc&limit=50"

Write-Host "Fetching queued emails..." -ForegroundColor Cyan
try {
    $emails = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
} catch {
    Write-Host "[ERROR] Failed to fetch queued emails:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    if ($_.ErrorDetails) { Write-Host $_.ErrorDetails }
    return
}

if (-not $emails) {
    Write-Host "No queued emails." -ForegroundColor Yellow
    return
}

Write-Host ("Found {0} queued emails." -f $emails.Count) -ForegroundColor Green

# 2) Prepare SMTP client
$smtp = New-Object System.Net.Mail.SmtpClient($smtpConf.smtp_host, [int]$smtpConf.smtp_port)
$smtp.EnableSsl = [bool]$smtpConf.enable_ssl
$smtp.Credentials = New-Object System.Net.NetworkCredential($smtpConf.username, $smtpConf.password)

foreach ($mail in $emails) {
    $id       = $mail.id
    $toEmail  = $mail.to_email
    $subject  = $mail.subject
    $body     = $mail.body

    Write-Host ""
    Write-Host "Sending email_log id=$id to $toEmail ..." -ForegroundColor Cyan

    $msg = New-Object System.Net.Mail.MailMessage
    $msg.From = $smtpConf.from_email
    $msg.To.Add($toEmail)
    $msg.Subject = $subject
    $msg.Body    = $body
    $msg.IsBodyHtml = $false

    $statusUri = "$SupabaseUrl/rest/v1/email_log?id=eq.$id"

    try {
        $smtp.Send($msg)
        Write-Host "Sent." -ForegroundColor Green

        $updateBody = @{
            status  = "sent"
            sent_at = (Get-Date).ToString("o")
        } | ConvertTo-Json

        Invoke-RestMethod -Uri $statusUri -Headers $headers -Method Patch -Body $updateBody
    }
    catch {
        Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red

        $errText = $_.Exception.Message
        $updateBody = @{
            status = "failed"
            error  = $errText
        } | ConvertTo-Json

        Invoke-RestMethod -Uri $statusUri -Headers $headers -Method Patch -Body $updateBody
    }
}
