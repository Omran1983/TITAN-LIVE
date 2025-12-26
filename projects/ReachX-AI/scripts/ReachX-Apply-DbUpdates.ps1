Param(
    [string]$SchemaFile = "F:\ReachX-AI\db\schema_reachx.sql",
    [string]$SeedFile   = "F:\ReachX-AI\db\reachx_seed_demo.sql"
)

$scriptRoot = Split-Path -Parent $PSCommandPath
$logRoot    = Join-Path (Split-Path -Parent $scriptRoot) "logs"
if (-not (Test-Path $logRoot)) {
    New-Item -ItemType Directory -Path $logRoot | Out-Null
}

Write-Host "=== ReachX-Apply-DbUpdates.ps1 ===" -ForegroundColor Cyan

if (-not $env:REACHX_DB_URL) {
    Write-Error "REACHX_DB_URL is not set. Set it to your Supabase Postgres connection string and re-run."
    exit 1
}

$runSql = Join-Path $scriptRoot "ReachX-RunSql.ps1"
if (-not (Test-Path $runSql)) {
    Write-Error "ReachX-RunSql.ps1 not found at $runSql"
    exit 1
}

# 1) Apply schema
if (Test-Path $SchemaFile) {
    Write-Host "`n[1/2] Applying schema from $SchemaFile" -ForegroundColor Yellow
    & $runSql -SqlFile $SchemaFile
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Schema apply failed. Aborting."
        exit $LASTEXITCODE
    }
} else {
    Write-Warning "Schema file not found at $SchemaFile – skipping."
}

# 2) Apply seed (demo data)
if (Test-Path $SeedFile) {
    Write-Host "`n[2/2] Applying seed from $SeedFile" -ForegroundColor Yellow
    & $runSql -SqlFile $SeedFile
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Seed apply failed."
        exit $LASTEXITCODE
    }
} else {
    Write-Warning "Seed file not found at $SeedFile – skipping."
}

Write-Host "`nAll DB updates applied successfully." -ForegroundColor Green
exit 0
