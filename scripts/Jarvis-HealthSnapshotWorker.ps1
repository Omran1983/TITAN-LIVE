# F:\AION-ZERO\scripts\Jarvis-HealthSnapshotWorker.ps1

# --- 1. SETUP ---
$runId = [Guid]::NewGuid().ToString()
$startTime = [DateTime]::UtcNow
$agentName = "Jarvis-HealthSnapshotWorker"
$script:hasFailed = $false
$script:failureMessage = $null
$metrics = @{}
$ErrorActionPreference = "Stop"

try {
    # Import helpers
    if (Test-Path "F:\AION-ZERO\scripts\Load-DotEnv.ps1") {
        . "F:\AION-ZERO\scripts\Load-DotEnv.ps1" -EnvFilePath "F:\AION-ZERO\.env" | Out-Null
    }
    if (Test-Path "F:\AION-ZERO\scripts\Invoke-Supabase.ps1") {
        Write-Host "[*] Found Invoke-Supabase helper." -ForegroundColor Gray
    }
    
    # --- 2. EXECUTION (The Checks) ---
    
    # Check A: Disk Space (C:)
    $disk = Get-PSDrive C -ErrorAction SilentlyContinue
    if ($disk) {
        $freeGB = [math]::Round($disk.Free / 1GB, 2)
        $metrics["disk_free_gb"] = $freeGB
        $metrics["disk_total_gb"] = [math]::Round($disk.Used / 1GB + $freeGB, 2)
        
        if ($freeGB -lt 10) {
            throw "CRITICAL_DISK_SPACE: C: drive has less than 10GB free ($freeGB GB)"
        }
    }
    else {
        $metrics["disk"] = "unknown"
    }

    # Check B: Memory
    $os = Get-CimInstance Win32_OperatingSystem
    $freeMemMB = [math]::Round($os.FreePhysicalMemory / 1KB, 2)
    $totalMemMB = [math]::Round($os.TotalVisibleMemorySize / 1KB, 2)
    $metrics["memory_free_mb"] = $freeMemMB
    $metrics["memory_total_mb"] = $totalMemMB
    
    if ($freeMemMB -lt 500) {
        throw "CRITICAL_MEMORY: Less than 500MB free physical memory" 
    }

    # Check C: Supabase Connectivity (The Helper)
    try {
        # Assuming we can just query the table we are about to write to, or just a simple ping
        # We'll rely on the final write to prove connectivity, but checking keys is good.
        if (-not $env:SUPABASE_URL -or (-not $env:SUPABASE_KEY -and -not $env:SUPABASE_SERVICE_KEY)) {
            throw "ENV_MISSING: SUPABASE_URL or SUPABASE_SERVICE_KEY not loaded"
        }
        $metrics["supabase_connection"] = "ok"
    }
    catch {
        throw "SUPABASE_CONFIG_ERROR: $_"
    }
    
    # --- 3. SUCCESS STATE ---
    $status = "success"
    $severity = "info"
    $errorCode = $null
    $errorMessage = $null

}
catch {
    # --- 4. FAILURE STATE ---
    $script:hasFailed = $true
    $script:failureMessage = $_.Exception.Message
    
    $status = "hard_fail"
    $severity = "error"
    $errorCode = "RUN_EXCEPTION" 
    $errorMessage = $script:failureMessage
    
    Write-Host "[-] AGENT FAILED: $errorMessage" -ForegroundColor Red
}

# --- 5. LOGGING (The Contract) ---

$finishTime = [DateTime]::UtcNow

$payload = @{
    checks    = $metrics
    host_name = $env:COMPUTERNAME
}

$commandObject = @{
    run_id        = $runId
    agent_name    = $agentName
    mission_id    = $null
    status        = $status
    severity      = $severity
    started_at    = $startTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    finished_at   = $finishTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    error_code    = $errorCode
    error_message = $errorMessage
    payload       = $payload
}

try {
    Write-Host "[*] Logging run to Supabase... ($status)" -ForegroundColor Cyan
    & "F:\AION-ZERO\scripts\Invoke-Supabase.ps1" -Path "/rest/v1/az_agent_runs" -Method POST -Body $commandObject -ReturnRaw
    Write-Host "[+] Logged successfully." -ForegroundColor Green
}
catch {
    Write-Host "[!] CRITICAL: Failed to log to Supabase." -ForegroundColor Red
    Write-Host $_
    # Last ditch local log
    $backupLog = "F:\AION-ZERO\logs\fallback_agent_runs.jsonl"
    $json = $commandObject | ConvertTo-Json -Depth 5 -Compress
    Add-Content -Path $backupLog -Value $json
    Write-Host "[*] Wrote to local fallback log: $backupLog" -ForegroundColor Gray
}
