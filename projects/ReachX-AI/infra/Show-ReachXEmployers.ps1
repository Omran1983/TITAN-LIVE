param(
    [string]$Status,          # e.g. new, contacted, in_discussion, closed_won, closed_lost
    [string]$Location,        # e.g. Mauritius
    [int]$Top = 50
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "================================"
Write-Host " REACHX-BLUE — EMPLOYER SNAPSHOT"
Write-Host "================================"
Write-Host ""

$SupabaseUrl = $env:SUPABASE_URL
$SupabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $SupabaseUrl -or -not $SupabaseKey) {
    Write-Host "ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set in environment."
    return
}

$headers = @{
    apikey        = $SupabaseKey
    Authorization = "Bearer $SupabaseKey"
    "Content-Type" = "application/json"
}

$selectCols = "id,employer_name,sector,location,contact_status,last_contacted_at,notes_internal"

$uri = "$SupabaseUrl/rest/v1/reachx_employers?select=$selectCols&order=created_at.desc&limit=$Top"

if ($Status) {
    $statusEsc = [uri]::EscapeDataString($Status)
    $uri += "&contact_status=eq.$statusEsc"
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
    Write-Host "No employers found for the current filter."
    return
}

# Stats by status
$byStatus = $rows | Group-Object -Property contact_status

Write-Host "Counts by contact_status:"
foreach ($g in $byStatus) {
    $label = if ($g.Name) { $g.Name } else { "(null)" }
    Write-Host ("  {0,-15} : {1}" -f $label, $g.Count)
}
Write-Host ""

# Simple table view
$rows |
    Select-Object `
        @{Name="Employer"; Expression = { $_.employer_name } },
        @{Name="Sector";   Expression = { $_.sector } },
        @{Name="Location"; Expression = { $_.location } },
        @{Name="Status";   Expression = { if ($_.contact_status) { $_.contact_status } else { "null" } } },
        @{Name="LastContacted"; Expression = {
            if ($_.last_contacted_at) {
                [DateTime]::Parse($_.last_contacted_at).ToString("yyyy-MM-dd HH:mm")
            } else {
                ""
            }
        }} |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Hint: filter by status or location, e.g.:"
Write-Host "  .\Show-ReachXEmployers.ps1 -Status contacted -Location ""Mauritius"""
Write-Host ""
