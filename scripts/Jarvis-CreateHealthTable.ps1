param()

Write-Host "=== Jarvis - Create az_health_snapshots table ===" -ForegroundColor Cyan

# Resolve script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load env
$loadEnv = Join-Path $scriptDir "Jarvis-LoadEnv.ps1"
if (Test-Path $loadEnv) {
    & $loadEnv
} else {
    Write-Host "WARNING: Jarvis-LoadEnv.ps1 not found at $loadEnv" -ForegroundColor Yellow
}

# SQL to create table + index
$sql = @"
create table if not exists public.az_health_snapshots (
    id              bigserial primary key,
    overall_status  text        not null,
    queue_depth     integer     not null,
    errors_last_10m integer     not null,
    avg_latency_ms  numeric,
    meta            jsonb       default '{}'::jsonb,
    created_at      timestamptz not null default now()
);

create index if not exists az_health_snapshots_created_at_idx
    on public.az_health_snapshots (created_at desc);
"@

# Use existing Jarvis-RunSql wrapper
$runSql = Join-Path $scriptDir "Jarvis-RunSql.ps1"
if (-not (Test-Path $runSql)) {
    Write-Host "ERROR: Jarvis-RunSql.ps1 not found at $runSql" -ForegroundColor Red
    exit 1
}

Write-Host "Running CREATE TABLE for az_health_snapshots via Jarvis-RunSql ..." -ForegroundColor DarkGray
& $runSql -Sql $sql

if ($LASTEXITCODE -eq 0) {
    Write-Host "az_health_snapshots table is ready." -ForegroundColor Green
} else {
    Write-Host "ERROR: Jarvis-RunSql reported a non-zero exit code." -ForegroundColor Red
    exit 1
}
