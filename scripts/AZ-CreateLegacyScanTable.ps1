param(
    # Supabase Postgres connection string
    [string]$DbUrl      = $env:SUPABASE_DB_URL,
    # Path to psql.exe (adjust if different)
    [string]$PsqlPath   = "C:\Program Files\PostgreSQL\16\bin\psql.exe"
)

$ErrorActionPreference = "Stop"

if (-not $DbUrl) {
    Write-Error "No database URL provided. Set SUPABASE_DB_URL env var or pass -DbUrl."
    exit 1
}

if (-not (Test-Path $PsqlPath)) {
    Write-Error "psql not found at: $PsqlPath"
    Write-Host "Update -PsqlPath to match your PostgreSQL client install."
    exit 1
}

$sql = @'
create table if not exists az_legacy_scans (
    id            bigserial primary key,
    machine_id    text not null,
    scanned_at    timestamptz not null,
    suspicious    integer not null,
    report_path   text,
    created_at    timestamptz default now()
);
'@

Write-Host "Running DDL against Supabase..."
Write-Host "psql: $PsqlPath"
Write-Host "DB:   (hidden)"

# Call psql with ON_ERROR_STOP so errors cause non-zero exit code
& $PsqlPath $DbUrl -v ON_ERROR_STOP=1 -c $sql

if ($LASTEXITCODE -eq 0) {
    Write-Host "Table az_legacy_scans is ready." -ForegroundColor Green
} else {
    Write-Error "psql exited with code $LASTEXITCODE"
    exit $LASTEXITCODE
}
