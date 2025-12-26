$ErrorActionPreference = "Stop"

$EnvFilePath = "F:\secrets\.env-main"

if (-not (Test-Path $EnvFilePath)) {
    Write-Host "Env file not found: $EnvFilePath" -ForegroundColor Red
    exit 1
}

$envLines = Get-Content -Path $EnvFilePath
$supLine  = $envLines | Where-Object { $_ -match '^\s*SUPABASE_URL=' }         | Select-Object -Last 1
$keyLine  = $envLines | Where-Object { $_ -match '^\s*SUPABASE_SERVICE_KEY=' } | Select-Object -Last 1

$SupabaseUrl = ($supLine -replace '^\s*SUPABASE_URL=', '').Trim()
$ServiceKey  = ($keyLine -replace '^\s*SUPABASE_SERVICE_KEY=', '').Trim()

Write-Host "SUPABASE_URL: $SupabaseUrl"
Write-Host "SERVICE_KEY length: $($ServiceKey.Length)"

$Headers = @{
    apikey         = $ServiceKey
    Authorization  = "Bearer $ServiceKey"
    "Content-Type" = "application/json"
    Prefer         = "return=representation"
}

# Minimal test payload (will probably 400, we want the error JSON)
$body = @{
    project = "ReachX"
} | ConvertTo-Json -Depth 4

$url = "$SupabaseUrl/rest/v1/az_commands"

Write-Host "POST => $url"
Write-Host "BODY:"
Write-Host $body

try {
    $resp = Invoke-WebRequest -Uri $url -Headers $Headers -Method Post -Body $body -ErrorAction Stop
    Write-Host "STATUS: $($resp.StatusCode)"
    Write-Host "RESPONSE:"
    Write-Host $resp.Content
} catch {
    Write-Host "STATUS: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    $respStream = $_.Exception.Response.GetResponseStream()
    $reader     = New-Object System.IO.StreamReader($respStream)
    $errBody    = $reader.ReadToEnd()
    Write-Host "ERROR BODY:" -ForegroundColor Yellow
    Write-Host $errBody
}
