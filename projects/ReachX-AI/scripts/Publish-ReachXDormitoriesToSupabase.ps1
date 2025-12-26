param(
    [string]$CsvPath     = "F:\ReachX-AI\data\normalised\dormitories-normalised.csv",
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
$deleteUri = "$base/rest/v1/dormitories?id=not.is.null"
$insertUri = "$base/rest/v1/dormitories"

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

Write-Host "Publishing dormitories from: $CsvPath" -ForegroundColor Cyan
Write-Host "→ Insert endpoint: $insertUri" -ForegroundColor Cyan

try {
    Write-Host "Clearing ALL rows in public.dormitories via: $deleteUri" -ForegroundColor Yellow
    Invoke-RestMethod -Uri $deleteUri -Headers $deleteHeaders -Method Delete | Out-Null
}
catch {
    Write-Host "Warning: failed to clear dormitories table: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

$rows = Import-Csv -Path $CsvPath
if (-not $rows -or $rows.Count -eq 0) {
    Write-Host "No dormitories found in CSV." -ForegroundColor Yellow
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
        name               = Trim-Value $r.name
        owner_name         = Trim-Value $r.owner_name
        contact_phone      = Trim-Value $r.contact_phone
        contact_email      = Trim-Value $r.contact_email
        country            = Trim-Value $r.country
        city               = Trim-Value $r.city
        area               = Trim-Value $r.area
        capacity_total     = if ($r.capacity_total) { [int]$r.capacity_total } else { $null }
        capacity_occupied  = if ($r.capacity_occupied) { [int]$r.capacity_occupied } else { $null }
        gender             = Trim-Value $r.gender
        notes              = Trim-Value $r.notes
    }

    if ([string]::IsNullOrWhiteSpace($body.name)) { continue }

    $json = $body | ConvertTo-Json -Depth 4
    try {
        $resp = Invoke-RestMethod -Uri $insertUri -Headers $insertHeaders -Method Post -Body "[$json]"
        $success++
        Write-Host "OK   -> $($body.name) [$($body.city)]" -ForegroundColor Green
    }
    catch {
        $fail++
        Write-Host "FAIL -> $($body.name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Dormitories — Done. Success: $success | Failed: $fail" -ForegroundColor Cyan
