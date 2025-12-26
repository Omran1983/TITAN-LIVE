param(
    [int]    $CommandId,
    [string] $Sql
)

Write-Host "=== Jarvis-RunSql ===" -ForegroundColor Cyan

# ---------------------------------------------------
# 1) Load environment variables
# ---------------------------------------------------
$SUPABASE_URL         = $env:SUPABASE_URL
$SUPABASE_SERVICE_KEY = $env:SUPABASE_SERVICE_KEY
$JARVIS_DB_CONN       = $env:JARVIS_DB_CONN

if (-not $SUPABASE_URL -or -not $SUPABASE_SERVICE_KEY) {
    Write-Host "ERROR: Missing SUPABASE_URL or SUPABASE_SERVICE_KEY" -ForegroundColor Red
    exit 1
}
if (-not $JARVIS_DB_CONN) {
    Write-Host "ERROR: Missing JARVIS_DB_CONN" -ForegroundColor Red
    exit 1
}

$headers = @{
    "apikey"        = $SUPABASE_SERVICE_KEY
    "Authorization" = "Bearer $SUPABASE_SERVICE_KEY"
    "Content-Type"  = "application/json"
}

# ---------------------------------------------------
# 2) If no SQL passed, fetch from az_commands
# ---------------------------------------------------
if (-not $Sql) {

    if (-not $CommandId) {
        Write-Host "ERROR: Must provide either -Sql or -CommandId" -ForegroundColor Red
        exit 1
    }

    $cmdUrl = "$SUPABASE_URL/rest/v1/az_commands?id=eq.$CommandId"
    Write-Host "Fetching SQL from az_commands id=$CommandId" -ForegroundColor DarkGray

    try {
        $resp = Invoke-RestMethod -Method Get -Uri $cmdUrl -Headers $headers
    } catch {
        Write-Host "ERROR fetching az_commands: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }

    if (-not $resp -or $resp.Count -eq 0) {
        Write-Host "ERROR: No az_commands row for id=$CommandId" -ForegroundColor Red
        exit 1
    }

    $Sql = $resp[0].generated_sql

    if (-not $Sql) {
        Write-Host "ERROR: generated_sql is NULL for id=$CommandId" -ForegroundColor Red
        exit 1
    }
}

Write-Host "SQL to execute:" -ForegroundColor DarkGray
Write-Host $Sql

# ---------------------------------------------------
# 3) Write SQL to temporary file
# ---------------------------------------------------
$tmpDir = Join-Path $PSScriptRoot "tmp"
if (-not (Test-Path $tmpDir)) {
    New-Item -ItemType Directory -Path $tmpDir | Out-Null
}

$rand    = Get-Random
$sqlFile = Join-Path $tmpDir ("run_{0}.sql" -f $rand)
$outFile = Join-Path $tmpDir ("stdout_{0}.txt" -f $rand)
$errFile = Join-Path $tmpDir ("stderr_{0}.txt" -f $rand)

$Sql | Set-Content -Path $sqlFile -Encoding UTF8

# ---------------------------------------------------
# 4) Execute SQL using psql
# ---------------------------------------------------
Write-Host "Executing via psql ..." -ForegroundColor DarkGray

& psql "$JARVIS_DB_CONN" -v ON_ERROR_STOP=1 -f "$sqlFile" 1> $outFile 2> $errFile
$exitCode = $LASTEXITCODE

# Read outputs safely
$stdout = ""
$stderr = ""

if (Test-Path $outFile) {
    $stdout = Get-Content $outFile -Raw
}
if (Test-Path $errFile) {
    $stderr = Get-Content $errFile -Raw
}

Write-Host "ExitCode = $exitCode" -ForegroundColor Yellow

# ---------------------------------------------------
# 5) If using CommandId, update az_commands
# ---------------------------------------------------
if ($CommandId) {

    $cmdUrl = "$SUPABASE_URL/rest/v1/az_commands?id=eq.$CommandId"

    if ($exitCode -eq 0) {
        $status   = "completed"
        $errorMsg = $null
    } else {
        $status   = "error"
        $errorMsg = "psql exit code $exitCode"
    }

    $logBlock = @"
SQL:
$Sql

STDOUT:
$stdout

STDERR:
$stderr
"@

    $body = @{
        status = $status
        logs   = $logBlock
        error  = $errorMsg
    } | ConvertTo-Json

    try {
        Invoke-RestMethod -Method Patch -Uri $cmdUrl -Headers $headers -Body $body | Out-Null
        Write-Host "az_commands updated." -ForegroundColor Green
    } catch {
        Write-Host "WARNING: Failed to PATCH az_commands: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# ---------------------------------------------------
# 6) Final exit code
# ---------------------------------------------------
if ($exitCode -eq 0) {
    Write-Host "SQL executed successfully." -ForegroundColor Green
    exit 0
} else {
    Write-Host "SQL execution failed." -ForegroundColor Red
    exit $exitCode
}
