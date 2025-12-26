
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Load Env
. "F:\AION-ZERO\scripts\Jarvis-LoadEnv.ps1"

$SupabaseUrl = $env:SUPABASE_URL
$ServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY
if (-not $ServiceKey) { $ServiceKey = $env:SUPABASE_SERVICE_KEY }
$Headers = @{ apikey = $ServiceKey; Authorization = "Bearer $ServiceKey"; "Content-Type" = "application/json" }


function Get-CommandStatus {
    param($Id)
    $url = "$SupabaseUrl/rest/v1/az_commands?select=status,result_json&id=eq.$Id"
    try {
        return Invoke-RestMethod -Method Get -Uri $url -Headers $Headers
    }
    catch {
        Write-Error "Get-CommandStatus Failed: $($_.Exception.Message)"
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            Write-Error "Response Body: $($reader.ReadToEnd())"
        }
        throw
    }
}

Write-Host "=== TEST: JARVIS SYSTEM ==="
Write-Host "SupabaseUrl: $SupabaseUrl"
if (-not $ServiceKey) { Write-Error "ServiceKey is MISSING!" }


# 1. INSERT COMMAND
$testPayload = @{
    project     = "AION-ZERO"
    action      = "ops"
    instruction = "Write-Output 'Hello from Automated Test'"
    status      = "queued"
    created_at  = (Get-Date).ToUniversalTime().ToString("o")
} | ConvertTo-Json

$Headers["Prefer"] = "return=representation"
try {
    $resp = Invoke-RestMethod -Method Post -Uri "$SupabaseUrl/rest/v1/az_commands" -Headers $Headers -Body $testPayload
}
catch {
    Write-Host "Create Command Failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Host "Response Body: $($reader.ReadToEnd())" -ForegroundColor Red
    }
    throw "Terminating due to POST failure."
}
$cmdId = $resp[0].id

Write-Host "Created Queued Command #$cmdId" -ForegroundColor Cyan

# 2. START WORKER JOB
Write-Host "Starting Jarvis-Worker.ps1 in background..."
$job = Start-Job -FilePath "F:\AION-ZERO\scripts\Jarvis-Worker.ps1"

# 3. POLL FOR COMPLETION
$maxRetries = 10
$n = 0
$success = $false

while ($n -lt $maxRetries) {
    Start-Sleep -Seconds 3
    $statusData = Get-CommandStatus -Id $cmdId
    $status = $statusData[0].status
    
    Write-Host "Check #$($n+1): Status = $status"
    
    # Stream worker logs
    $logs = Receive-Job -Job $job -Keep
    if ($logs) {
        Write-Host "[WORKER LOGS]:" -ForegroundColor DarkGray
        $logs | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    }
    
    if ($status -eq "completed") {
        Write-Host "SUCCESS: Command completed!" -ForegroundColor Green
        Write-Host "Result: $($statusData[0].result_json)" -ForegroundColor Gray
        $success = $true
        break
    }
    
    if ($status -eq "error") {
        Write-Error "Test Failed: Command status is 'error'."
        break
    }
    
    $n++
}

# 4. CLEANUP
Stop-Job $job
Remove-Job $job

if (-not $success) {
    Write-Error "Test Timed Out or Failed."
}
else {
    Write-Host "`nTest Passed Successfully." -ForegroundColor Green
}
