param(
    [Parameter(Mandatory = $true)]
    [string]$SqlFile,

    [string]$ConnectionString,

    [string]$LogFile = "F:\ReachX-AI\logs\ReachX-RunSql.log"
)

Write-Host "=== ReachX-RunSql.ps1 ===" -ForegroundColor Cyan
Write-Host "SQL file      : $SqlFile"
Write-Host "Log file      : $LogFile"

if (-not (Test-Path $SqlFile)) {
    Write-Error "SQL file not found: $SqlFile"
    exit 1
}

if (-not $ConnectionString) {
    if ($env:REACHX_DB_URL) {
        $ConnectionString = $env:REACHX_DB_URL
        Write-Host "Using REACHX_DB_URL from environment." -ForegroundColor Yellow
    } elseif ($env:SUPABASE_DB_URL) {
        $ConnectionString = $env:SUPABASE_DB_URL
        Write-Host "Using SUPABASE_DB_URL from environment." -ForegroundColor Yellow
    } else {
        Write-Error "No ConnectionString provided and REACHX_DB_URL / SUPABASE_DB_URL not set."
        exit 1
    }
}

# Basic check for psql
$psql = Get-Command psql -ErrorAction SilentlyContinue
if (-not $psql) {
    Write-Error "psql not found in PATH. Install PostgreSQL client tools or add psql to PATH."
    exit 1
}

# Ensure log directory exists
$logDir = Split-Path $LogFile -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"[$timestamp] Running SQL file '$SqlFile'" | Tee-Object -FilePath $LogFile -Append | Out-Host

try {
    & psql "$ConnectionString" -v ON_ERROR_STOP=1 -f "$SqlFile" 2>&1 `
        | Tee-Object -FilePath $LogFile -Append | Out-Host

    if ($LASTEXITCODE -ne 0) {
        throw "psql exited with code $LASTEXITCODE"
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] SUCCESS applying schema '$SqlFile'" | Tee-Object -FilePath $LogFile -Append | Out-Host
}
catch {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] ERROR applying schema '$SqlFile' -> $_" | Tee-Object -FilePath $LogFile -Append | Out-Host
    exit 1
}
