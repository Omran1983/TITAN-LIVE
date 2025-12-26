<#
    Jarvis-DbDump.ps1
    Full database dump for ReachX / AION-ZERO
    Saves each table as JSON with timestamp.
#>

# ===============================
# CONFIG
# ===============================
$ErrorActionPreference = "Stop"

# Load environment
. "F:\tweakops\Load-DotEnv.ps1" -EnvFilePath "F:\AION-ZERO\.env"

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_KEY) {
    Write-Error "Missing SUPABASE_URL or SUPABASE_SERVICE_KEY in environment."
    exit 1
}

$supabaseUrl = $env:SUPABASE_URL
$serviceKey  = $env:SUPABASE_SERVICE_KEY

$headers = @{
    "apikey"        = $serviceKey
    "Authorization" = "Bearer $serviceKey"
    "Content-Type"  = "application/json"
}

# Tables to dump
$tables = @(
    "reachx_employers",
    "reachx_workers",
    "reachx_requests",
    "reachx_assignments",
    "reachx_dormitories"
)

# Backup folder
$ts = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$backupRoot = "F:\AION-ZERO\backups\$ts"

if (-not (Test-Path $backupRoot)) {
    New-Item -ItemType Directory -Path $backupRoot | Out-Null
}

# Log file
$logPath = Join-Path $backupRoot "dump.log"

"=== ReachX DB Dump starting at $ts ===" |
    Tee-Object -FilePath $logPath -Append | Out-Host


# ===============================
# MAIN LOOP
# ===============================
$baseUrl = $supabaseUrl.TrimEnd('/')

foreach ($t in $tables) {
    try {
        # FIXED URL
        $uri = "$baseUrl/rest/v1/$($t)?select=*&limit=2000"

        $line = "Dumping table $t from $uri"
        $line | Tee-Object -FilePath $logPath -Append | Out-Host

        $data = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers

        $outFile = Join-Path $backupRoot ("{0}_{1}.json" -f $t, $ts)
        $data | ConvertTo-Json -Depth 8 | Set-Content -Path $outFile -Encoding UTF8

        # Count rows
        $rows = 0
        if ($null -ne $data -and $data -is [System.Array]) {
            $rows = $data.Count
        } elseif ($null -ne $data) {
            $rows = 1
        }

        ("Saved {0} rows from {1} -> {2}" -f $rows, $t, $outFile) |
            Tee-Object -FilePath $logPath -Append | Out-Host
    }
    catch {
        ("Error dumping {0}: {1}" -f $t, $_.Exception.Message) |
            Tee-Object -FilePath $logPath -Append | Out-Host
    }
}

"Done." | Tee-Object -FilePath $logPath -Append | Out-Host
Write-Host "=== ReachX DB Dump finished ==="
