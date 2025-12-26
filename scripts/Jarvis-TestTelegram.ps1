$ErrorActionPreference = "Stop"

cd F:\AION-ZERO
& ".\scripts\Jarvis-LoadEnv.ps1"

$token  = $env:TELEGRAM_BOT_TOKEN
$chatId = $env:TELEGRAM_CHAT_ID

if ([string]::IsNullOrWhiteSpace($chatId)) {
    $chatId = "1920600504"
}

Write-Host "TestTelegram: token starts with: $($token.Substring(0,6))..." 
Write-Host "TestTelegram: chatId = $chatId"

if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Host "ERROR: TELEGRAM_BOT_TOKEN is empty. Set it in .env" -ForegroundColor Red
    exit 1
}

$uri  = "https://api.telegram.org/bot$token/sendMessage"
$now  = (Get-Date).ToString("o")
$body = @{
    chat_id = $chatId
    text    = "Jarvis direct test ping at $now"
}

Write-Host "TestTelegram: calling $uri"

try {
    $resp = Invoke-RestMethod -Method Post -Uri $uri -Body $body
    Write-Host "TestTelegram: SUCCESS, response:"
    $resp | ConvertTo-Json -Depth 10
}
catch {
    Write-Host "TestTelegram: FAILED" -ForegroundColor Red
    $ex = $_.Exception
    Write-Host "Message: $($ex.Message)"

    if ($ex.Response -ne $null) {
        try {
            $stream = $ex.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $respBody = $reader.ReadToEnd()
            Write-Host "Telegram error body:"
            Write-Host $respBody
        }
        catch {
            Write-Host "Could not read error body."
        }
    } else {
        Write-Host "No HTTP response body."
    }
}
