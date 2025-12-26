<#
.SYNOPSIS
    Apply correct SUPABASE env variables to ReachX UI.

.DESCRIPTION
    This script updates the ReachX UI `.env` file with current
    SUPABASE_URL and SUPABASE_ANON_KEY from your global `.env` in AION-ZERO.
#>

param(
    [string]$ProjectRoot = "F:\ReachX-AI"
)

Write-Host "=== ReachX ENV Apply Tool ===" -ForegroundColor Cyan

$envFile = Join-Path $ProjectRoot ".env"
if (-not (Test-Path $envFile)) {
    Write-Warning "ReachX .env does not exist. Creating a new one..."
}

# Load global environment first
& "F:\AION-ZERO\scripts\Use-ProjectEnv.ps1"

# Values from global env
$SUPABASE_URL  = $env:SUPABASE_URL
$SUPABASE_ANON = $env:SUPABASE_ANON_KEY

if (-not $SUPABASE_URL -or -not $SUPABASE_ANON) {
    throw "Missing SUPABASE env vars in global .env. Cannot proceed."
}

$lines = @(
    "SUPABASE_URL=$SUPABASE_URL"
    "SUPABASE_ANON_KEY=$SUPABASE_ANON"
)

$lines | Out-File -FilePath $envFile -Encoding utf8 -Force

Write-Host "ReachX .env updated:" -ForegroundColor Green
Write-Host "  SUPABASE_URL      = $SUPABASE_URL"
Write-Host "  SUPABASE_ANON_KEY = ${SUPABASE_ANON:0:8}********"

Write-Host "`nDone."
