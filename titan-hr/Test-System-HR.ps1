$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
. "F:\AION-ZERO\scripts\Jarvis-LoadEnv.ps1"
$SupabaseUrl = $env:SUPABASE_URL
$ServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY
if (-not $ServiceKey) { $ServiceKey = $env:SUPABASE_SERVICE_KEY }
$Headers = @{ apikey = $ServiceKey; Authorization = "Bearer $ServiceKey"; "Content-Type" = "application/json" }

Write-Host "=== TEST: TITAN-HR SYSTEM INTEGRATION ==="

# 1. Insert HR Command
$payload = @{
    project     = "AION-ZERO"
    action      = "hr"
    instruction = "Run Compliance Check for Q1 2026"
    status      = "queued"
    created_at  = (Get-Date).ToUniversalTime().ToString("o")
} | ConvertTo-Json

try {
    Write-Host "Queuing HR Command..."
    $Headers["Prefer"] = "return=representation"
    $resp = Invoke-RestMethod -Method Post -Uri "$SupabaseUrl/rest/v1/az_commands" -Headers $Headers -Body $payload
    $cmdId = $resp[0].id
    Write-Host " -> Command #$cmdId Queued." -ForegroundColor Cyan
}
catch {
    Write-Error "POST Failed: $($_.Exception.Message)"
    exit 1
}

# 2. Start Worker (Background)
Write-Host "Starting Jarvis-Worker..."
$job = Start-Job -FilePath "F:\AION-ZERO\scripts\Jarvis-Worker.ps1"

# 3. Poll
$max = 15
$n = 0
while ($n -lt $max) {
    Start-Sleep -Seconds 3
    
    # Check logs
    $logs = Receive-Job -Job $job -Keep
    if ($logs) { $logs | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor DarkGray }

    # Check DB status
    try {
        $check = Invoke-RestMethod -Method Get -Uri "$SupabaseUrl/rest/v1/az_commands?id=eq.$cmdId&select=status,result_json" -Headers $Headers
        $status = $check[0].status
        Write-Host " -> [$n] Status: $status"
        
        if ($status -eq "completed") {
            Write-Host "SUCCESS: HR Command Executed!" -ForegroundColor Green
            Write-Host "Result Summary: $($check[0].result_json)" -ForegroundColor Gray
            break
        }
        if ($status -eq "error") {
            Write-Error "FAIL: Agent reported error."
            break
        }
    }
    catch {
        Write-Warning "Poll error: $_"
    }
    $n++
}

Stop-Job $job
Remove-Job $job

if ($n -ge $max) { Write-Error "TIMEOUT" }
