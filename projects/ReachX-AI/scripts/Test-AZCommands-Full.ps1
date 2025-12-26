$ErrorActionPreference = "Stop"

$EnvFilePath = "F:\secrets\.env-main"

if (-not (Test-Path $EnvFilePath)) {
    Write-Host "Env file not found: $EnvFilePath" -ForegroundColor Red
    exit 1
}

$envLines = Get-Content -Path $EnvFilePath
$supLine  = $envLines | Where-Object { $_ -match "^\s*SUPABASE_URL=" }         | Select-Object -Last 1
$keyLine  = $envLines | Where-Object { $_ -match "^\s*SUPABASE_SERVICE_KEY=" } | Select-Object -Last 1

$SupabaseUrl = ($supLine -replace "^\s*SUPABASE_URL=", "").Trim()
$ServiceKey  = ($keyLine -replace "^\s*SUPABASE_SERVICE_KEY=", "").Trim()

Write-Host "SUPABASE_URL: $SupabaseUrl"
Write-Host "SERVICE_KEY length: $($ServiceKey.Length)"

$Headers = @{
    apikey         = $ServiceKey
    Authorization  = "Bearer $ServiceKey"
    "Content-Type" = "application/json"
    Prefer         = "return=representation"
}

# Minimal real-looking command matching our schema guess
$bodyObj = @{
    project      = "ReachX"
    target_agent = "Jarvis-Code-Worker"
    task_type    = "BUILD_UI"
    description  = "Debug single ReachX BUILD_UI command"
    status       = "pending"   # try enum-friendly value
    payload      = @{ page = "dashboard.html"; root_id = "reachx-dashboard-root" }
}

$bodyJson = $bodyObj | ConvertTo-Json -Depth 6
$url      = "$SupabaseUrl/rest/v1/az_commands"

Write-Host "POST => $url"
Write-Host "BODY:"
Write-Host $bodyJson

try {
    $resp = Invoke-WebRequest -Uri $url -Headers $Headers -Method Post -Body $bodyJson -ErrorAction Stop
    Write-Host "STATUS: $($resp.StatusCode)"
    Write-Host "RESPONSE:"
    Write-Host $resp.Content
} catch {
    $respObj = $_.Exception.Response
    if ($respObj -ne $null) {
        Write-Host "STATUS: $($respObj.StatusCode.value__)" -ForegroundColor Red
        $respStream = $respObj.GetResponseStream()
        $reader     = New-Object System.IO.StreamReader($respStream)
        $errBody    = $reader.ReadToEnd()
        Write-Host "ERROR BODY:" -ForegroundColor Yellow
        Write-Host $errBody
    } else {
        Write-Host "Unknown error:"
        Write-Host $_
    }
}
