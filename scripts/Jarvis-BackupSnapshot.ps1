param(
    [string]$Label = "manual"
)

$ErrorActionPreference = "Stop"

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Error "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set."
    exit 1
}

$baseUrl = $env:SUPABASE_URL.TrimEnd('/')

$headers = @{
    apikey        = $env:SUPABASE_SERVICE_ROLE_KEY
    Authorization = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
}

$timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = "F:\AION-ZERO\backups\supabase"
$folderName = "backup_{0}_{1}" -f $timestamp, $Label
$backupPath = Join-Path $backupRoot $folderName

New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

Write-Host "Starting Supabase backup to $backupPath ..." -ForegroundColor Cyan

# Keep this list small for now – we can expand later
$tables = @(
    "az_commands",
    "jarvis_jobs",
    "jarvis_runs",
    "reachx_employers",
    "reachx_workers"
)

foreach ($t in $tables) {
    try {
        # 🛠 Build URI safely, no weird $select interpolation
        $uri = "{0}/rest/v1/{1}?select=*&limit=2000" -f $baseUrl, $t

        Write-Host ("Dumping table {0} from {1}" -f $t, $uri) -ForegroundColor Yellow

        $data = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers

        $outFile = Join-Path $backupPath ("{0}_{1}.json" -f $t, $timestamp)
        $data | ConvertTo-Json -Depth 8 | Set-Content -Path $outFile -Encoding UTF8

        $rows = 0
        if ($null -ne $data -and $data -is [System.Array]) {
            $rows = $data.Count
        } elseif ($null -ne $data) {
            $rows = 1
        }

        Write-Host ("Saved {0} rows from {1} -> {2}" -f $rows, $t, $outFile) -ForegroundColor Green
    }
    catch {
        Write-Warning ("Failed to dump table {0}: {1}" -f $t, $_.Exception.Message)
    }
}

Write-Host "Backup completed at $backupPath" -ForegroundColor Cyan
