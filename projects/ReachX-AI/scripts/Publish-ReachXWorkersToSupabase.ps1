param(
    [string]$CsvPath     = "F:\ReachX-AI\data\normalised\workers-normalised.csv",
    [string]$SupabaseUrl = $env:REACHX_SUPABASE_URL,
    [string]$SupabaseKey = $env:REACHX_SUPABASE_SERVICE_KEY
)

if (-not (Test-Path $CsvPath)) {
    Write-Host "CSV not found: $CsvPath" -ForegroundColor Red
    return
}
if (-not $SupabaseUrl -or -not $SupabaseKey) {
    Write-Host "Supabase URL or Key missing in environment." -ForegroundColor Red
    return
}

# Normalise base URL
$base = $SupabaseUrl.TrimEnd("/")

# Endpoints
$deleteUri = "$base/rest/v1/workers?id=not.is.null"
$insertUri = "$base/rest/v1/workers"

# Headers
$deleteHeaders = @{
    apikey        = $SupabaseKey
    Authorization = "Bearer $SupabaseKey"
    Prefer        = "return=representation"
}
$insertHeaders = @{
    apikey         = $SupabaseKey
    Authorization  = "Bearer $SupabaseKey"
    "Content-Type" = "application/json"
    Prefer         = "return=representation"
}

Write-Host "Publishing workers from: $CsvPath" -ForegroundColor Cyan
Write-Host "→ Insert endpoint: $insertUri" -ForegroundColor Cyan

# 1) HARD RESET TABLE (no duplicates, ever)
try {
    Write-Host "Clearing ALL rows in public.workers via: $deleteUri" -ForegroundColor Yellow
    Invoke-RestMethod -Uri $deleteUri -Headers $deleteHeaders -Method Delete | Out-Null
}
catch {
    Write-Host "Warning: failed to clear workers table: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

# 2) LOAD CSV
$rows = Import-Csv -Path $CsvPath
if (-not $rows -or $rows.Count -eq 0) {
    Write-Host "No rows found in CSV." -ForegroundColor Yellow
    return
}

function Trim-Value {
    param($v)
    if ($null -eq $v) { return $null }
    $trim = $v.ToString().Trim()
    if ($trim -eq "") { return $null }
    return $trim
}

$success = 0
$fail    = 0

foreach ($r in $rows) {

    $body = [pscustomobject]@{
        full_name             = Trim-Value $r.full_name
        primary_skill         = Trim-Value $r.primary_skill
        secondary_skills      = Trim-Value $r.secondary_skills
        skill_category        = Trim-Value $r.skill_category

        experience_years      = Trim-Value $r.experience_years
        current_country       = Trim-Value $r.current_country
        current_state         = Trim-Value $r.current_state
        current_city          = Trim-Value $r.current_city
        origin_country        = Trim-Value $r.origin_country
        preferred_destination = Trim-Value $r.preferred_destination

        languages             = Trim-Value $r.languages
        salary_expect_min     = Trim-Value $r.salary_expect_min
        salary_expect_max     = Trim-Value $r.salary_expect_max
        salary_currency       = Trim-Value $r.salary_currency

        availability_label    = Trim-Value $r.availability_label
        availability_date     = Trim-Value $r.availability_date

        phone                 = Trim-Value $r.phone
        whatsapp              = Trim-Value $r.whatsapp
        email                 = Trim-Value $r.email

        source_platform       = Trim-Value $r.source_platform
        source_country        = Trim-Value $r.source_country
        source_raw_id         = Trim-Value $r.source_raw_id
        source_raw_url        = Trim-Value $r.source_raw_url

        notes                 = Trim-Value $r.notes
    }

    if ([string]::IsNullOrWhiteSpace($body.full_name)) {
        continue
    }

    $json = $body | ConvertTo-Json -Depth 4

    try {
        $resp = Invoke-RestMethod -Uri $insertUri -Headers $insertHeaders -Method Post -Body "[$json]"
        $success++
        Write-Host "OK   -> $($body.full_name) [$($body.primary_skill)]" -ForegroundColor Green
    }
    catch {
        $fail++
        Write-Host "FAIL -> $($body.full_name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Done. Success: $success | Failed: $fail" -ForegroundColor Cyan
