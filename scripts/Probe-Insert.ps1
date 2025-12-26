$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

. "F:\AION-ZERO\scripts\Jarvis-LoadEnv.ps1"

$SupabaseUrl = $env:SUPABASE_URL
$ServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY
if (-not $ServiceKey) { $ServiceKey = $env:SUPABASE_SERVICE_KEY }

Write-Host "Probing INSERT to az_commands..."

$payload = @{
    project     = "AION-ZERO"
    action      = "ops"
    instruction = "Probe Test"
    status      = "queued"
} | ConvertTo-Json

try {
    $resp = Invoke-RestMethod -Method Post -Uri "$SupabaseUrl/rest/v1/az_commands" -Headers @{ 
        apikey         = $ServiceKey
        Authorization  = "Bearer $ServiceKey" 
        "Content-Type" = "application/json"
        "Prefer"       = "return=representation"
    } -Body $payload
    
    Write-Host "Success! ID: $($resp[0].id)" -ForegroundColor Green
}
catch {
    Write-Host "Insert Failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Host "Body: $($reader.ReadToEnd())" -ForegroundColor Red
    }
}
