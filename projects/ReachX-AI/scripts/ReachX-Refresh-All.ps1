param(
    [string]$EnvPath = "F:\ReachX-AI\.env"
)

$ErrorActionPreference = "Stop"

function Get-ReachXEnv {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        throw "ReachX .env file not found at $Path"
    }

    $map = @{}
    Get-Content $Path |
      Where-Object { $_ -and -not $_.StartsWith("#") } |
      ForEach-Object {
        $parts = $_ -split "=", 2
        if ($parts.Count -eq 2) {
          $name  = $parts[0].Trim()
          $value = $parts[1].Trim()
          if ($name) { $map[$name] = $value }
        }
      }

    return $map
}

function Get-SupabaseRestBase {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl
    )

    $base = $BaseUrl.Trim().TrimEnd('/')

    if ($base.ToLower().EndsWith('/rest/v1')) {
        return $base
    } else {
        return "$base/rest/v1"
    }
}

function Import-SupabaseCsv {
    param(
        [string]$CsvPath,
        [string]$Table,
        [string]$RestBase,
        [string]$ApiKey,
        [switch]$ClearFirst  # kept for compatibility, but ignored
    )

    if (-not (Test-Path $CsvPath)) {
        Write-Warning "CSV not found for table '$Table': $CsvPath (skipping)"
        return
    }

    $uri = "{0}/{1}" -f $RestBase, $Table

    Write-Host "Publishing $Table from: $CsvPath"
    Write-Host "→ Insert endpoint: $uri"

    $rows = Import-Csv -Path $CsvPath
    if (-not $rows) {
        Write-Warning "No rows in CSV for table '$Table' (nothing to insert)."
        return
    }

    # Normalise empty strings → $null (fix invalid date "" issues)
    foreach ($row in $rows) {
        foreach ($prop in $row.PSObject.Properties) {
            if ($prop.Value -is [string]) {
                $val = $prop.Value.Trim()
                if ($val -eq "") {
                    $prop.Value = $null
                }
            }
        }
    }

    $json = $rows | ConvertTo-Json -Depth 5

    $headers = @{
        apikey         = $ApiKey
        Authorization  = "Bearer $ApiKey"
        Prefer         = "return=minimal,resolution=merge-duplicates"
        "Content-Type" = "application/json"
    }

    try {
        Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $json
        Write-Host "Inserted $($rows.Count) row(s) into $Table."
    }
    catch {
        Write-Warning "Error inserting into '$Table': $_"
    }
}

$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
Write-Host "=== ReachX Refresh All - $timestamp ==="

Write-Host ">>> Load Supabase env"
$envMap = Get-ReachXEnv -Path $EnvPath
$sbUrl  = $envMap["REACHX_SUPABASE_URL"]
$sbKey  = $envMap["REACHX_SUPABASE_SERVICE_KEY"]
if (-not $sbKey) {
    $sbKey = $envMap["REACHX_SUPABASE_ANON_KEY"]
}

if (-not $sbUrl -or -not $sbKey) {
    throw "Missing REACHX_SUPABASE_URL or REACHX_SUPABASE_SERVICE_KEY/ANON in .env"
}

Write-Host "ReachX Supabase env set:"
Write-Host "  REACHX_SUPABASE_URL = $sbUrl"
Write-Host "  SERVICE_KEY length  = $($sbKey.Length)"

$restBase = Get-SupabaseRestBase -BaseUrl $sbUrl

Write-Host ">>> Publish Workers CSV → Supabase"
$workersCsv = "F:\ReachX-AI\data\normalised\workers-normalised.csv"
Import-SupabaseCsv -CsvPath $workersCsv -Table "workers" -RestBase $restBase -ApiKey $sbKey -ClearFirst

Write-Host "=== ReachX Refresh All - Done ===" -ForegroundColor Green
