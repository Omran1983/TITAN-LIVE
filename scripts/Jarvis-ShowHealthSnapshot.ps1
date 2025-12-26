# FILE: F:\AION-ZERO\scripts\Jarvis-ShowHealthSnapshot.ps1
# Purpose: Query Supabase for latest security + dev + deploy runs and show a summary.

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

        if ($value.StartsWith('"') -and $value.EndsWith('"')) {
            $value = $value.Substring(1, $value.Length - 2)
        } elseif ($value.StartsWith("'") -and $value.EndsWith("'")) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        Set-Item -Path ("Env:{0}" -f $name) -Value $value
    }
}

Write-Host "=== Jarvis Health Snapshot ==="
Write-Host "BaseDir : $baseDir"
Write-Host "EnvFile : $envFile"
Write-Host ""

Load-EnvFile -Path $envFile

$supabaseUrl = $env:VITE_SUPABASE_URL
$serviceKey  = $env:SUPABASE_SERVICE_KEY

if (-not $supabaseUrl) {
    Write-Error "VITE_SUPABASE_URL not set in env."
    exit 1
}
if (-not $serviceKey) {
    Write-Error "SUPABASE_SERVICE_KEY not set in env."
    exit 1
}

$supabaseUrl = $supabaseUrl.TrimEnd('/')

$headers = @{
    "apikey"        = $serviceKey
    "Authorization" = "Bearer $serviceKey"
}

function Get-Json {
    param(
        [string]$Endpoint
    )

    try {
        return Invoke-RestMethod -Method Get -Uri $Endpoint -Headers $headers
    }
    catch {
        Write-Host "ERROR calling $Endpoint : $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 1) Latest legacy scan
Write-Host "---- Legacy Python Scan ----"
$legacyEndpoint = "$supabaseUrl/rest/v1/az_legacy_scans?select=*&order=scanned_at.desc&limit=1"
$legacy = Get-Json -Endpoint $legacyEndpoint

if ($null -eq $legacy -or $legacy.Count -eq 0) {
    Write-Host "No legacy scan records found."
} else {
    $row = if ($legacy -is [System.Array]) { $legacy[0] } else { $legacy }

    $machine   = $row.machine_id
    $scannedAt = $row.scanned_at
    $suspicious = $row.suspicious
    $report    = $row.report_path

    Write-Host ("Machine   : {0}" -f $machine)
    Write-Host ("ScannedAt : {0}" -f $scannedAt)
    Write-Host ("Suspicious: {0}" -f $suspicious)
    Write-Host ("Report    : {0}" -f $report)
}
Write-Host ""

# 2) Latest project runs (dev + deploy) per project / type
Write-Host "---- Project Runs (latest) ----"

# Get last N runs and group locally
$projectRunsEndpoint = "$supabaseUrl/rest/v1/az_project_runs?select=*&order=finished_at.desc&limit=50"
$runs = Get-Json -Endpoint $projectRunsEndpoint

if ($null -eq $runs -or $runs.Count -eq 0) {
    Write-Host "No project run records found."
} else {
    # Normalize into array
    $list = @()
    if ($runs -is [System.Array]) {
        $list = $runs
    } else {
        $list = @($runs)
    }

    # Group by Project + RunType, keep latest per group
    $grouped = $list |
        Sort-Object finished_at -Descending |
        Group-Object -Property project_name, run_type

    $summary = foreach ($g in $grouped) {
        $latest = $g.Group | Select-Object -First 1

        [PSCustomObject]@{
            Project    = $latest.project_name
            RunType    = $latest.run_type
            Status     = $latest.status
            FinishedAt = $latest.finished_at
            Message    = $latest.message
        }
    }

    $summary |
        Sort-Object Project, RunType |
        Format-Table -AutoSize
}

Write-Host ""
Write-Host "=== End of Jarvis Health Snapshot ==="
