param(
    [string]$EnvPath
)

# ------------------------------------------------------------
# Load-Supabase.ps1
# - Prefer environment variables (set by Use-ProjectEnv.ps1)
# - Fallback to .env file only if needed
# - Ensure SUPABASE_URL and SUPABASE_SERVICE_KEY end up in $env:*
# ------------------------------------------------------------

if (-not $EnvPath -or $EnvPath.Trim() -eq '') {
    $projectRoot = Split-Path $PSScriptRoot -Parent
    $EnvPath = Join-Path $projectRoot ".env"
}

# 1) Try environment variables first (preferred)
$supabaseUrl = $env:SUPABASE_URL
$supabaseKey = $env:SUPABASE_SERVICE_KEY

if (-not $supabaseUrl -and $env:SBURL) {
    $supabaseUrl = $env:SBURL
}
if (-not $supabaseKey -and $env:SBKEY) {
    $supabaseKey = $env:SBKEY
}

# 2) If still missing, optionally fall back to .env file
if (-not $supabaseUrl -or -not $supabaseKey) {
    if (Test-Path $EnvPath) {
        $lines = Get-Content -Path $EnvPath
        foreach ($line in $lines) {
            if ($line -match '^\s*#') { continue }
            if (-not $line.Trim()) { continue }

            $parts = $line -split '=', 2
            if ($parts.Count -ne 2) { continue }

            $name  = $parts[0].Trim()
            $value = $parts[1].Trim()

            switch ($name) {
                'SUPABASE_URL'         { if (-not $supabaseUrl) { $supabaseUrl = $value } }
                'SUPABASE_SERVICE_KEY' { if (-not $supabaseKey) { $supabaseKey = $value } }
                'SBURL'                { if (-not $supabaseUrl) { $supabaseUrl = $value } }
                'SBKEY'                { if (-not $supabaseKey) { $supabaseKey = $value } }
            }
        }
    }
}

if (-not $supabaseUrl) {
    throw "Load-Supabase.ps1: SUPABASE_URL/SBURL is missing (env + $EnvPath)"
}
if (-not $supabaseKey) {
    throw "Load-Supabase.ps1: SUPABASE_SERVICE_KEY/SBKEY is missing (env + $EnvPath)"
}

# Export to environment for downstream scripts
$env:SUPABASE_URL = $supabaseUrl
$env:SUPABASE_SERVICE_KEY = $supabaseKey

[PSCustomObject]@{
    Url = $supabaseUrl
    Key = $supabaseKey
}
