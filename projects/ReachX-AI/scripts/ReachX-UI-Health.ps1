$ErrorActionPreference = "Stop"

function Get-ReachXEnv {
    if ($PSScriptRoot) {
        $projectRoot = Split-Path -Path $PSScriptRoot -Parent
    } elseif ($MyInvocation.MyCommand.Path) {
        $scriptDir   = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
        $projectRoot = Split-Path -Path $scriptDir -Parent
    } else {
        $projectRoot = "F:\ReachX-AI"
    }

    $envPath = Join-Path $projectRoot ".env"

    if (!(Test-Path $envPath)) {
        throw "Missing .env at $envPath"
    }

    $envMap = @{}
    Get-Content $envPath | ForEach-Object {
        if (-not $_) { return }
        $line = $_.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { return }
        $parts = $line -split "=", 2
        if ($parts.Count -ne 2) { return }
        $key = $parts[0].Trim()
        $val = $parts[1].Trim()
        if ($key) { $envMap[$key] = $val }
    }

    if (-not $envMap.ContainsKey("REACHX_SUPABASE_URL")) {
        throw "REACHX_SUPABASE_URL missing in .env"
    }

    $svcKey = $null
    if ($envMap.ContainsKey("REACHX_SUPABASE_SERVICE_KEY")) {
        $svcKey = $envMap["REACHX_SUPABASE_SERVICE_KEY"]
    } elseif ($envMap.ContainsKey("REACHX_SUPABASE_ANON_KEY")) {
        $svcKey = $envMap["REACHX_SUPABASE_ANON_KEY"]
    } else {
        throw "No Supabase key found (REACHX_SUPABASE_SERVICE_KEY or REACHX_SUPABASE_ANON_KEY)."
    }

    return [PSCustomObject]@{
        Url = $envMap["REACHX_SUPABASE_URL"]
        Key = $svcKey
    }
}

$cfg     = Get-ReachXEnv
$baseUrl = $cfg.Url.TrimEnd("/")

# Use plain table names, same as seeder
$tables = @("agents","employers","dormitories","workers")

$headers = @{
    apikey        = $cfg.Key
    Authorization = "Bearer " + $cfg.Key
}

$logPath = "F:\Jarvis\logs\reachx-heartbeat.log"
$logDir  = Split-Path $logPath -Parent
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$utcNow  = [DateTime]::UtcNow.ToString("yyyy-MM-dd HH:mm:ssZ")

foreach ($t in $tables) {
    # EXACT same pattern as seeder, but GET (no query params at all)
    $uri = "$baseUrl/rest/v1/$t"

    Write-Host "CHECK $t → $uri" -ForegroundColor Cyan

    try {
        $resp = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get

        if ($null -eq $resp) {
            $count = 0
        } else {
            $count = (@($resp)).Count
        }

        $msg = "$utcNow | ReachX-UI-Health | $t count = $count"
        Write-Host $msg -ForegroundColor Green
        Add-Content -Path $logPath -Value $msg
    }
    catch {
        $detail = $_.ErrorDetails.Message
        if (-not $detail) { $detail = $_.Exception.Message }
        $msg = "$utcNow | ReachX-UI-Health | $t ERROR: $detail"
        Write-Warning $msg
        Add-Content -Path $logPath -Value $msg
    }
}
