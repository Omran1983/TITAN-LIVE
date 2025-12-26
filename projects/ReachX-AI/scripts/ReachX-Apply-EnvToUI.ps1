# F:\ReachX-AI\scripts\ReachX-Apply-EnvToUI.ps1
# Simple patcher: read SUPABASE_URL and SUPABASE_ANON_KEY from .env
# then replace the literal strings SUPABASE_URL / SUPABASE_ANON_KEY in all UI HTML files.

$ErrorActionPreference = 'Stop'

# Resolve paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root      = Split-Path -Parent $scriptDir
$envFile   = Join-Path $root '.env'
$uiRoot    = Join-Path $root 'infra\ReachX-Workers-UI-v1'

if (-not (Test-Path $envFile)) {
    Write-Error "Missing .env file at $envFile"
    exit 1
}

# Load .env into a hashtable
$envMap = @{}

Get-Content $envFile | Where-Object {
    $_ -and $_.Trim() -ne '' -and $_ -notmatch '^\s*#'
} | ForEach-Object {
    if ($_ -match '^\s*([^=]+)\s*=\s*(.*)\s*$') {
        $key = $matches[1].Trim()
        $val = $matches[2].Trim()
        $envMap[$key] = $val
    }
}

if (-not $envMap.ContainsKey('SUPABASE_URL') -or -not $envMap.ContainsKey('SUPABASE_ANON_KEY')) {
    Write-Error "SUPABASE_URL or SUPABASE_ANON_KEY not found in $envFile"
    Write-Host "Keys found:" -ForegroundColor Yellow
    $envMap.Keys | Sort-Object | ForEach-Object { Write-Host "  $_" }
    exit 1
}

$supabaseUrl  = $envMap['SUPABASE_URL']
$supabaseAnon = $envMap['SUPABASE_ANON_KEY']

Write-Host "Applying .env to UI..." -ForegroundColor Cyan
Write-Host "  URL  = $supabaseUrl"
Write-Host "  ANON = [hidden]"

# Patch all HTML files under the UI directory
Get-ChildItem $uiRoot -Filter '*.html' | ForEach-Object {
    $filePath = $_.FullName
    $name     = $_.Name

    $original = Get-Content $filePath -Raw
    $patched  = $original

    # Replace literal tokens SUPABASE_URL and SUPABASE_ANON_KEY everywhere
    $patched = $patched -replace 'SUPABASE_URL',     [System.Text.RegularExpressions.Regex]::Escape($supabaseUrl)
    $patched = $patched -replace 'SUPABASE_ANON_KEY',[System.Text.RegularExpressions.Regex]::Escape($supabaseAnon)

    if ($patched -ne $original) {
        Set-Content -Path $filePath -Value $patched -Encoding UTF8
        Write-Host "Patched UI: $name" -ForegroundColor Green
    } else {
        Write-Host "No SUPABASE_* config changed in: $name (skipped)" -ForegroundColor DarkGray
    }
}

Write-Host "Done. All UI HTML now read from $envFile" -ForegroundColor Green
