$ErrorActionPreference = "Stop"

$logDir     = "F:\AION-ZERO\logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

$historyJsonl = Join-Path $logDir "educonnect-status-history.jsonl"
$historyMd    = Join-Path $logDir "educonnect-status-history.md"

$baseUrl = "https://educonnect-hq-lite.dubsy1983-51e.workers.dev"
$url     = "$baseUrl/status"

Write-Host "Calling $url ..." -ForegroundColor Cyan

try {
    $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30
    $statusCode = $resp.StatusCode
    $rawBody    = $resp.Content
} catch {
    $statusCode = 0
    $rawBody    = $null
    Write-Host "Request failed: $($_.Exception.Message)" -ForegroundColor Red
}

$now = Get-Date

$parsed = $null
if ($rawBody) {
    try {
        $parsed = $rawBody | ConvertFrom-Json
    } catch {
        Write-Host "Failed to parse JSON, logging raw body." -ForegroundColor DarkYellow
    }
}

$record = [PSCustomObject]@{
    timestamp  = $now.ToString("o")
    statusCode = $statusCode
    body       = if ($parsed) { $parsed } else { $rawBody }
}

# Append as JSONL
$recordJson = $record | ConvertTo-Json -Depth 6 -Compress
Add-Content -Path $historyJsonl -Value $recordJson

# Append as Markdown summary
$line = @"
### $( $now.ToString("yyyy-MM-dd HH:mm:ss") )

- Status code: $statusCode
- Raw body:
\`\`\`json
$rawBody
\`\`\`

"@

Add-Content -Path $historyMd -Value $line

Write-Host "EduConnect status logged to:" -ForegroundColor Green
Write-Host "  $historyJsonl" -ForegroundColor Green
Write-Host "  $historyMd" -ForegroundColor Green
