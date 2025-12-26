param(
    [string]$CsvPath     = "F:\ReachX-AI\data\normalised\agents-normalised.csv",
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
$deleteUri = "$base/rest/v1/agents?id=not.is.null"
$insertUri = "$base/rest/v1/agents"

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

Write-Host "Publishing agents from: $CsvPath" -ForegroundColor Cyan
Write-Host "→ Insert endpoint: $insertUri" -ForegroundColor Cyan

try {
    Write-Host "Clearing ALL rows in public.agents via: $deleteUri" -ForegroundColor Yellow
    Invoke-RestMethod -Uri $deleteUri -Headers $deleteHeaders -Method Delete | Out-Null
}
catch {
    Write-Host "Warning: failed to clear agents table: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

$rows = Import-Csv -Path $CsvPath
if (-not $rows -or $rows.Count -eq 0) {
    Write-Host "No agents found in CSV." -ForegroundColor Yellow
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
        agency_name   = Trim-Value $r.agency_name
        country       = Trim-Value $r.country
        city          = Trim-Value $r.city
        contact_name  = Trim-Value $r.contact_name
        contact_email = Trim-Value $r.contact_email
        contact_phone = Trim-Value $r.contact_phone
        whatsapp      = Trim-Value $r.whatsapp
        lanes         = Trim-Value $r.lanes
        status        = Trim-Value $r.status
        notes         = Trim-Value $r.notes
    }

    if ([string]::IsNullOrWhiteSpace($body.agency_name)) { continue }

    $json = $body | ConvertTo-Json -Depth 4
    try {
        $resp = Invoke-RestMethod -Uri $insertUri -Headers $insertHeaders -Method Post -Body "[$json]"
        $success++
        Write-Host "OK   -> $($body.agency_name) [$($body.country)]" -ForegroundColor Green
    }
    catch {
        $fail++
        Write-Host "FAIL -> $($body.agency_name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Agents — Done. Success: $success | Failed: $fail" -ForegroundColor Cyan
