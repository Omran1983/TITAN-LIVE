$ErrorActionPreference = "Stop"

function Get-ReachXEnv {
    $projectRoot = Split-Path $PSScriptRoot -Parent
    $envPath     = Join-Path $projectRoot ".env"

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

function Clear-Table {
    param(
        [Parameter(Mandatory = $true)][string]$Table
    )

    # Delete all rows where id IS NOT NULL (works for uuid & bigint)
    $uri = "$baseUrl/rest/v1/$Table?id=is.not.null"

    $headers = @{
        apikey        = $cfg.Key
        Authorization = "Bearer $($cfg.Key)"
        Prefer        = "return=minimal"
    }

    Write-Host "Clearing table $Table..." -ForegroundColor Yellow
    try {
        Invoke-RestMethod -Uri $uri -Headers $headers -Method Delete | Out-Null
        Write-Host "Cleared $Table" -ForegroundColor Green
    }
    catch {
        $detail = $_.ErrorDetails.Message
        if (-not $detail) { $detail = $_.Exception.Message }
        Write-Warning ("Failed to clear {0}: {1}" -f $Table, $detail)
    }
}

# WARNING: deletes ALL rows in these tables
Clear-Table "agents"
Clear-Table "employers"
Clear-Table "dormitories"
Clear-Table "workers"

Write-Host "All demo tables cleared. Reseeding..." -ForegroundColor Cyan

& "$PSScriptRoot\ReachX-Seed-Minimum.ps1"
