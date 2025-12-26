param(
    [int]$Top = 50,
    [string]$Sector,
    [string]$Location,
    [string]$ExportsDir = "F:\ReachX-AI\exports"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "====================================="
Write-Host " REACHX-BLUE — EXPORT EMPLOYERS CSV "
Write-Host "====================================="
Write-Host ""

if (-not (Test-Path $ExportsDir)) {
    New-Item -Path $ExportsDir -ItemType Directory -Force | Out-Null
}

$SupabaseUrl = $env:SUPABASE_URL
$SupabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $SupabaseUrl -or -not $SupabaseKey) {
    Write-Host "ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set."
    return
}

$headers = @{
    apikey        = $SupabaseKey
    Authorization = "Bearer $SupabaseKey"
    "Content-Type" = "application/json"
}

$selectCols = "id,employer_name,sector,location,country,source,contact_name,contact_role,contact_email,contact_phone,notes"

$uri = "$SupabaseUrl/rest/v1/reachx_employers?select=$selectCols&order=created_at.desc&limit=$Top"

if ($Sector) {
    $sectorEsc = [uri]::EscapeDataString($Sector)
    $uri += "&sector=eq.$sectorEsc"
}

if ($Location) {
    $locEsc = [uri]::EscapeDataString($Location)
    $uri += "&location=eq.$locEsc"
}

Write-Host "Querying employers from Supabase..."
Write-Host ("  {0}" -f $uri)
Write-Host ""

$rows = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get

if (-not $rows -or $rows.Count -eq 0) {
    Write-Host "No employers returned from Supabase."
    return
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outPath   = Join-Path $ExportsDir ("reachx-employers-{0}.csv" -f $timestamp)

$rows | Export-Csv -Path $outPath -NoTypeInformation -Encoding UTF8

Write-Host ("Exported {0} employers to:" -f $rows.Count)
Write-Host ("  {0}" -f $outPath)
Write-Host ""
Write-Host "You can open this CSV in Excel, Sheets, etc., or feed it into another script."
