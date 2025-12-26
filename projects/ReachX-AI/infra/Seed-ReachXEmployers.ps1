param(
    [string]$CsvPath = "F:\ReachX-AI\data\reachx_employers_seed.csv"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=====================================" 
Write-Host " REACHX-BLUE — SEED EMPLOYERS (CSV) " 
Write-Host "=====================================" 
Write-Host ""

if (-not (Test-Path $CsvPath)) {
    Write-Host ("ERROR: CSV file not found: {0}" -f $CsvPath)
    return
}

$SupabaseUrl = $env:SUPABASE_URL
$SupabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $SupabaseUrl -or -not $SupabaseKey) {
    Write-Host "ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set in environment."
    return
}

Write-Host ("Using Supabase: {0}" -f $SupabaseUrl)
Write-Host ("Using CSV     : {0}" -f $CsvPath)
Write-Host ""

$headers = @{
    apikey        = $SupabaseKey
    Authorization = "Bearer $SupabaseKey"
    "Content-Type" = "application/json"
    Prefer        = "resolution=merge-duplicates,return=representation"
}

$uri = "$SupabaseUrl/rest/v1/reachx_employers?on_conflict=employer_name,location"

$rows = Import-Csv -Path $CsvPath

if (-not $rows -or $rows.Count -eq 0) {
    Write-Host "No rows found in CSV. Nothing to seed."
    return
}

$success = 0
$fail    = 0

foreach ($row in $rows) {
    $payload = @{
        employer_name = $row.employer_name
        sector        = $row.sector
        location      = $row.location
        country       = $row.country
        source        = $row.source
        contact_name  = $row.contact_name
        contact_role  = $row.contact_role
        contact_email = $row.contact_email
        contact_phone = $row.contact_phone
        notes         = $row.notes
    }

    # Clean out empty values
    $clean = @{}
    foreach ($kv in $payload.GetEnumerator()) {
        if ($kv.Value -and $kv.Value -ne "") {
            $clean[$kv.Key] = $kv.Value
        }
    }

    if (-not $clean.ContainsKey("employer_name")) {
        Write-Host "Skipping row with empty employer_name."
        continue
    }

    $json = $clean | ConvertTo-Json -Depth 5
    $body = "[$json]"

    try {
        $result = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body
        $success++
        Write-Host ("OK  : {0} ({1})" -f $row.employer_name, $row.location)
    }
    catch {
        $fail++
        Write-Host ("FAIL: {0} ({1}) => {2}" -f $row.employer_name, $row.location, $_.Exception.Message)
    }
}

Write-Host ""
Write-Host ("Seed complete. Success = {0}, Failed = {1}" -f $success, $fail)
