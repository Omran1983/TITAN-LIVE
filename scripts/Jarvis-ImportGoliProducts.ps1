<#
    Jarvis-ImportGoliProducts.ps1
    -----------------------------
    Agent wrapper for importing Goli products into aogrl_ds_products.

    - Calls Python scraper: F:\AION-ZERO\agents\import_goli_products.py
    - Writes structured run info into az_agent_runs
    - Uses SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY from environment
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$Project = "aogrl-ds"
)

$ErrorActionPreference = "Stop"

# ---------- Paths & logging ----------

$rootDir = "F:\AION-ZERO"
$logDir = Join-Path $rootDir "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$logPath = Join-Path $logDir "Jarvis-ImportGoliProducts.log"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[{0}] [{1}] {2}" -f $timestamp, $Level, $Message
    Add-Content -Path $logPath -Value $line
}

Write-Log "=== Jarvis-ImportGoliProducts run started (Project=$Project) ==="

# ---------- Environment Loader (Manual Override for Reliability) ----------
# Explicitly loading .env from AOGRL-DS if not present in session
if (-not $env:SUPABASE_URL) {
    $envFile = "F:\AION-ZERO\universe\AOGRL-DS\okasina-fashion-store-vite\.env"
    if (Test-Path $envFile) {
        Write-Log "Loading credentials from $envFile"
        Get-Content $envFile | ForEach-Object {
            if ($_ -match "^\s*([^#=]+)=(.*)$") {
                $var = $matches[1].Trim()
                $val = $matches[2].Trim()
                # Determine which key to mapped
                if ($var -eq "VITE_SUPABASE_URL") { $env:SUPABASE_URL = $val; Write-Log "Set SUPABASE_URL" }
                if ($var -eq "SUPABASE_SERVICE_ROLE_KEY") { $env:SUPABASE_SERVICE_ROLE_KEY = $val; Write-Log "Set SUPABASE_SERVICE_ROLE_KEY" }
            }
        }
    }
    else {
        Write-Log ".env file not found at $envFile" "WARN"
    }
}

# ---------- Supabase helper (same pattern as Watchdog) ----------

function Write-AgentRunToSupabase {
    param(
        [string]$AgentName,
        [string]$Status,
        [string]$Severity,
        [datetime]$StartedAt,
        [datetime]$FinishedAt,
        [string]$ErrorCode,
        [string]$ErrorMessage,
        [object]$Payload
    )

    $supabaseUrl = $env:SUPABASE_URL
    $supabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY

    if (-not $supabaseUrl -or -not $supabaseKey) {
        Write-Log "Supabase env vars SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are missing." "ERROR"
        return
    }

    $runId = [guid]::NewGuid()

    $bodyObj = @{
        run_id        = $runId
        agent_name    = $AgentName
        mission_id    = $null
        status        = $Status
        severity      = $Severity
        started_at    = $StartedAt.ToUniversalTime().ToString("o")
        finished_at   = $FinishedAt.ToUniversalTime().ToString("o")
        error_code    = $ErrorCode
        error_message = $ErrorMessage
        payload       = $Payload
    }

    $bodyJson = $bodyObj | ConvertTo-Json -Depth 6

    $headers = @{
        "apikey"        = $supabaseKey
        "Authorization" = "Bearer $supabaseKey"
        "Content-Type"  = "application/json"
        "Prefer"        = "return=minimal"
    }

    $endpoint = "$supabaseUrl/rest/v1/az_agent_runs"

    try {
        Invoke-RestMethod -Method Post -Uri $endpoint -Headers $headers -Body $bodyJson | Out-Null
        Write-Log "Recorded agent run in az_agent_runs (run_id=$runId)." "INFO"
    }
    catch {
        Write-Log "Failed to record agent run in az_agent_runs: $($_.Exception.Message)" "ERROR"
    }
}

# ---------- Run the Python scraper ----------

$startTime = Get-Date
$status = "success"
$severity = "info"
$errorCode = $null
$errorMsg = $null

$pythonExe = "python"   # adjust to 'py' or full path if needed
$scriptPath = Join-Path $rootDir "agents\import_goli_products.py"

try {
    if (-not (Test-Path $scriptPath)) {
        throw "Python scraper not found at $scriptPath"
    }

    Write-Log "Running Python scraper: $pythonExe $scriptPath"

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $pythonExe
    $psi.Arguments = "`"$scriptPath`""
    $psi.WorkingDirectory = $rootDir
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    # Pass environment variables to child process
    $psi.EnvironmentVariables["SUPABASE_URL"] = $env:SUPABASE_URL
    $psi.EnvironmentVariables["SUPABASE_SERVICE_ROLE_KEY"] = $env:SUPABASE_SERVICE_ROLE_KEY

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $null = $proc.Start()

    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()

    $proc.WaitForExit()

    if ($stdout) {
        Write-Log "Scraper STDOUT:`n$stdout"
    }
    if ($stderr) {
        Write-Log "Scraper STDERR:`n$stderr" "WARN"
    }

    if ($proc.ExitCode -ne 0) {
        $status = "hard_fail"
        $severity = "error"
        $errorCode = "SCRAPER_EXIT_CODE_$($proc.ExitCode)"
        $errorMsg = "Goli import scraper exited with code $($proc.ExitCode)."
        Write-Log $errorMsg "ERROR"
    }
    else {
        Write-Log "Goli import scraper completed successfully."
    }
}
catch {
    $status = "hard_fail"
    $severity = "error"
    $errorCode = "SCRAPER_EXCEPTION"
    $errorMsg = $_.Exception.Message
    Write-Log "Exception in Jarvis-ImportGoliProducts: $errorMsg" "ERROR"
}

$endTime = Get-Date

# Build payload summary for az_agent_runs
$payload = @{
    project    = $Project
    source_url = "https://goli.com/pages/order"
}

Write-AgentRunToSupabase `
    -AgentName  "Jarvis-ImportGoliProducts" `
    -Status     $status `
    -Severity   $severity `
    -StartedAt  $startTime `
    -FinishedAt $endTime `
    -ErrorCode  $errorCode `
    -ErrorMessage $errorMsg `
    -Payload    $payload

if ($status -eq "success") {
    Write-Log "Jarvis-ImportGoliProducts run completed successfully."
    exit 0
}
else {
    Write-Log "Jarvis-ImportGoliProducts run completed with errors." "WARN"
    exit 1
}
