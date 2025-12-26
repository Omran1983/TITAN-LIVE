# FILE: F:\AION-ZERO\scripts\Jarvis-PostProjectRun.ps1
# Purpose: Post a dev/deploy run record to Supabase (az_project_runs)

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("dev", "deploy")]
    [string]$RunType,

    [Parameter(Mandatory = $true)]
    [ValidateSet("success", "failed")]
    [string]$Status,

    [string]$LogPath,
    [datetime]$StartedAt,
    [datetime]$FinishedAt,
    [string]$Message
)

$ErrorActionPreference = "Stop"

$baseDir = "F:\AION-ZERO"
$envFile = Join-Path $baseDir ".env"

function Load-EnvFile {
    param(
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        Write-Error "Env file not found: $Path"
        exit 1
    }

    $lines = Get-Content -Path $Path
    foreach ($line in $lines) {
        $trim = $line.Trim()
        if (-not $trim) { continue }
        if ($trim.StartsWith("#")) { continue }

        $idx = $trim.IndexOf("=")
        if ($idx -lt 1) { continue }

        $name  = $trim.Substring(0, $idx).Trim()
        $value = $trim.Substring($idx + 1).Trim()

        # Strip surrounding quotes
        if ($value.StartsWith('"') -and $value.EndsWith('"')) {
            $value = $value.Substring(1, $value.Length - 2)
        } elseif ($value.StartsWith("'") -and $value.EndsWith("'")) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        # Set env var properly
        Set-Item -Path ("Env:{0}" -f $name) -Value $value
    }
}

Write-Host "[PostProjectRun] Loading env vars from: $envFile"
Load-EnvFile -Path $envFile

# Supabase URL & service key
$supabaseUrl = $env:VITE_SUPABASE_URL
$serviceKey  = $env:SUPABASE_SERVICE_KEY

if (-not $supabaseUrl) {
    Write-Error "[PostProjectRun] VITE_SUPABASE_URL not set in env."
    exit 1
}
if (-not $serviceKey) {
    Write-Error "[PostProjectRun] SUPABASE_SERVICE_KEY not set in env."
    exit 1
}

$supabaseUrl = $supabaseUrl.TrimEnd('/')

# Machine ID
$machineId = $env:AZ_MACHINE_ID
if (-not $machineId) {
    $machineId = $env:COMPUTERNAME
}

# Timestamps
$finished = if ($FinishedAt) { $FinishedAt } else { Get-Date }
$started  = $StartedAt

# Body object
$body = [ordered]@{
    machine_id   = $machineId
    project_name = $ProjectName
    run_type     = $RunType
    status       = $Status
    finished_at  = $finished.ToUniversalTime().ToString("o")
}

if ($started) {
    $body.started_at = $started.ToUniversalTime().ToString("o")
}
if ($LogPath) {
    $body.log_path = $LogPath
}
if ($Message) {
    $body.message = $Message
}

$json = $body | ConvertTo-Json -Depth 5

$endpoint = "$supabaseUrl/rest/v1/az_project_runs"
Write-Host "[PostProjectRun] POST $endpoint"
Write-Host "[PostProjectRun] Body:"
Write-Host $json

$headers = @{
    "apikey"        = $serviceKey
    "Authorization" = "Bearer $serviceKey"
    "Content-Type"  = "application/json"
    "Prefer"        = "return=representation"
}

try {
    $resp = Invoke-RestMethod -Method Post -Uri $endpoint -Headers $headers -Body $json
    Write-Host "[PostProjectRun] Supabase response:"
    $resp | ConvertTo-Json -Depth 5 | Write-Host
}
catch {
    Write-Host "[PostProjectRun] ERROR posting to Supabase: $($_.Exception.Message)"
    throw
}
