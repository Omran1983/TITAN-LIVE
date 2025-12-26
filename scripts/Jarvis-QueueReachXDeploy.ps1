# Jarvis-QueueReachXDeploy.ps1 (no meta, debug kept)
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$loadEnvPath = Join-Path $ScriptDir 'Jarvis-LoadEnv.ps1'
if (Test-Path $loadEnvPath) {
    & $loadEnvPath
}

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in env." -ForegroundColor Red
    exit 1
}

$headers = @{
    apikey         = $env:SUPABASE_SERVICE_ROLE_KEY
    Authorization  = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    Accept         = "application/json"
    "Content-Type" = "application/json"
    Prefer         = "return=representation"
}

$body = @{
    project = "reachx"
    action  = "deploy"
    agent   = "deployment_agent"
    status  = "queued"
}

$json = $body | ConvertTo-Json -Depth 10
$url  = "$($env:SUPABASE_URL)/rest/v1/az_commands"

Write-Host "Queuing ReachX deploy command..." -ForegroundColor Cyan
Write-Host "POST $url" -ForegroundColor DarkGray
Write-Host "Payload:" -ForegroundColor DarkGray
Write-Host $json -ForegroundColor DarkGray

try {
    $resp = Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $json
    Write-Host "Supabase response:" -ForegroundColor Green
    $resp | Format-List
    Write-Host "Done. Check az_commands for new 'reachx / deploy / queued' row." -ForegroundColor Green
}
catch {
    Write-Host "Supabase returned an error:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    $resp = $_.Exception.Response
    if ($resp -ne $null) {
        $stream = $resp.GetResponseStream()
        if ($stream -ne $null) {
            $reader = New-Object System.IO.StreamReader($stream)
            $responseBody = $reader.ReadToEnd()
            Write-Host "Supabase error body:" -ForegroundColor Yellow
            Write-Host $responseBody -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "No response body available." -ForegroundColor DarkYellow
    }
}
