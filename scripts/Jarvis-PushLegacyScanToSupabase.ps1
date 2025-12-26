# FILE: F:\AION-ZERO\scripts\Jarvis-PushLegacyScanToSupabase.ps1
# Purpose: Read latest legacy scan report and push summary to Supabase

$ErrorActionPreference = "Stop"

# --- FIXED FILE LOCATIONS ---
$LogsDir    = "F:\AION-ZERO\logs"
$ToolsDir   = "F:\AION-ZERO\tools"
$EnvFile    = "F:\AION-ZERO\.env"
$MachineIdEnvVar = "AZ_MACHINE_ID"

Write-Host "LogsDir  : $LogsDir"
Write-Host "ToolsDir : $ToolsDir"
Write-Host "EnvFile  : $EnvFile"

# --- Load env vars from .env file ---

if (Test-Path $EnvFile) {
    Write-Host "Loading env vars from: $EnvFile"
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if (-not $line) { return }                  # skip empty
        if ($line.StartsWith("#")) { return }       # skip comments
        if ($line -notmatch "=") { return }         # skip malformed

        $parts = $line -split "=", 2
        $name  = $parts[0].Trim()
        $value = $parts[1].Trim()

        # Strip surrounding quotes if present
        if ($value.StartsWith("'") -and $value.EndsWith("'")) {
            $value = $value.Substring(1, $value.Length - 2)
        } elseif ($value.StartsWith('"') -and $value.EndsWith('"')) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        if ($name) {
            Set-Item -Path ("Env:{0}" -f $name) -Value $value
        }
    }
} else {
    Write-Error "Env file not found: $EnvFile"
    exit 1
}

# --- Config: HARD-CODED URL, SERVICE KEY FROM ENV ---

# Your real Supabase project URL (NO MORE PLACEHOLDERS)
$supabaseUrl = "https://abkprecmhitqmmlzxfad.supabase.co"

# Service key comes from .env (SUPABASE_SERVICE_KEY)
$serviceKey  = $env:SUPABASE_SERVICE_KEY

if (-not $serviceKey) {
    Write-Error "SUPABASE_SERVICE_KEY is not set in environment/.env"
    exit 1
}

# Normalize base URL (remove trailing slash)
$supabaseUrl = $supabaseUrl.TrimEnd('/')

# --- Machine ID ---

$machineId = $null
$machineIdItem = Get-Item ("Env:{0}" -f $MachineIdEnvVar) -ErrorAction SilentlyContinue
if ($machineIdItem) {
    $machineId = $machineIdItem.Value
}
if (-not $machineId) {
    $machineId = $env:COMPUTERNAME
}
if (-not $machineId) {
    Write-Error "Could not determine machine_id (no $MachineIdEnvVar or COMPUTERNAME)."
    exit 1
}

Write-Host "Machine ID : $machineId"

# --- Latest legacy scan log (timestamp only) ---

if (-not (Test-Path $LogsDir)) {
    Write-Error "Logs directory does not exist: $LogsDir"
    exit 1
}

$latestLog = Get-ChildItem -Path $LogsDir -Filter "legacy-scan-*.log" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $latestLog) {
    Write-Error "No legacy-scan-*.log files found in $LogsDir"
    exit 1
}

Write-Host "Using log file: $($latestLog.FullName)"

$scannedAt = $latestLog.LastWriteTimeUtc.ToString("o")
Write-Host "Scanned at (UTC): $scannedAt"

# --- Latest report file in tools dir ---

[int]$suspicious = 0
$reportPath = $null

if (-not (Test-Path $ToolsDir)) {
    Write-Error "Tools directory does not exist: $ToolsDir"
    exit 1
}

$latestReport = Get-ChildItem -Path $ToolsDir -Filter "python_legacy_scan_report-*.txt" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($latestReport) {
    $reportPath = $latestReport.FullName
    Write-Host "Using report file: $reportPath"

    $reportLines = Get-Content $latestReport.FullName

    # Count lines that look like findings ("- F:\..." etc)
    $suspicious = ($reportLines | Where-Object {
        $_.Trim().StartsWith("- ")
    }).Count

    Write-Host "Derived suspicious count from report: $suspicious"
} else {
    Write-Warning "No python_legacy_scan_report-*.txt found in $ToolsDir."
    $suspicious = 0
}

Write-Host "Final suspicious count: $suspicious"
Write-Host "Final report path     : $reportPath"

# --- Supabase POST ---

$endpoint = "$supabaseUrl/rest/v1/az_legacy_scans"

$headers = @{
    "apikey"        = $serviceKey
    "Authorization" = "Bearer $serviceKey"
    "Content-Type"  = "application/json"
    "Prefer"        = "return=representation"
}

$bodyObj = [ordered]@{
    machine_id  = $machineId
    scanned_at  = $scannedAt
    suspicious  = $suspicious
    report_path = $reportPath
}

$bodyJson = ($bodyObj | ConvertTo-Json -Depth 4)

Write-Host "POST $endpoint"
Write-Host "Body:"
Write-Host $bodyJson

try {
    $response = Invoke-RestMethod -Method Post -Uri $endpoint -Headers $headers -Body $bodyJson
    Write-Host "Supabase response:"
    $response | ConvertTo-Json -Depth 6
}
catch {
    Write-Error "Failed to POST to Supabase: $($_.Exception.Message)"
    if ($_.ErrorDetails) {
        Write-Host "Error details:"
        Write-Host $_.ErrorDetails
    }
    exit 1
}

Write-Host "Legacy scan result pushed successfully."
