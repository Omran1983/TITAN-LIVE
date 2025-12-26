$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

. "F:\AION-ZERO\scripts\Jarvis-LoadEnv.ps1"

$SupabaseUrl = $env:SUPABASE_URL
$ServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY
if (-not $ServiceKey) { $ServiceKey = $env:SUPABASE_SERVICE_KEY }

Write-Host "Probing table az_commands..."

try {
    $resp = Invoke-RestMethod -Method Get -Uri "$SupabaseUrl/rest/v1/az_commands?select=count" -Headers @{ apikey = $ServiceKey; Authorization = "Bearer $ServiceKey" }
    Write-Host "Success! Response: $($resp | ConvertTo-Json -Depth 1)" -ForegroundColor Green
}
catch {
    Write-Host "Probe Failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Host "Body: $($reader.ReadToEnd())" -ForegroundColor Red
    }
}
