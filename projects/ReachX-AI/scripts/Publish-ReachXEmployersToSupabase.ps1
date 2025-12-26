param(
    [string]$CsvPath     = "F:\ReachX-AI\data\normalised\employers-normalised.csv",
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

$base      = $SupabaseUrl.TrimEnd("/")
$deleteUri = "$base/rest/v1/employers?id=not.is.null"
$insertUri = "$base/rest/v1/employers"

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

Write-Host "Publishing employers from: $CsvPath" -ForegroundColor Cyan
Write-Host "→ Insert endpoint: $insertUri" -ForegroundColor Cyan

try {
    Write-Host "Clearing ALL rows in public.employers via: $deleteUri" -ForegroundColor Yellow
    Invoke-RestMethod -Uri $deleteUri -Headers $deleteHeaders -Method Delete | Out-Null
}
catch {
    Write-Host "Warning: failed to clear employers table: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

$rows = Import-Csv -Path $CsvPath
if (-not $rows -or $rows.Count -eq 0) {
    Write-Host "No employers found in CSV." -ForegroundColor Yellow
    return
}

function Trim-Value {
    param($v)
    if ($null -eq $v) { return $null }
    $t = $v.ToString().Trim()
    if ($t -eq "") { return $null }
    return $t
}

$success = 0; $fail = 0

foreach ($r in $rows) {
    $body = [pscustomobject]@{
        company_name       = Trim-Value $r.company_name
        contact_name       = Trim-Value $r.contact_name
        contact_email      = Trim-Value $r.contact_email
        contact_phone      = Trim-Value $r.contact_phone
        country            = Trim-Value $r.country
        city               = Trim-Value $r.city
        sector             = Trim-Value $r.sector
        headcount_estimate = if ($r.headcount_estimate) { [int]$r.headcount_estimate } else { $null }
        notes              = Trim-Value $r.notes
    }

    if ([string]::IsNullOrWhiteSpace($body.company_name)) { continue }

    $json = $body | ConvertTo-Json -Depth 4
    try {
        $resp = Invoke-RestMethod -Uri $insertUri -Headers $insertHeaders -Method Post -Body "[$json]"
        $success++
        Write-Host "OK   -> $($body.company_name) [$($body.sector)]" -ForegroundColor Green
    }
    catch {
        $fail++
        Write-Host "FAIL -> $($body.company_name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Employers — Done. Success: $success | Failed: $fail" -ForegroundColor Cyan
