param(
    [Parameter(Mandatory = $true)]
    [string]$EmployerName,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [string]$Status  = "contacted",   # e.g. new, contacted, in_discussion, closed_won, closed_lost
    [string]$Channel = "manual",      # email, whatsapp, linkedin, phone, manual
    [string]$Note    = "Contacted"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==========================================="
Write-Host " REACHX-BLUE — MARK EMPLOYER CONTACTED    "
Write-Host "==========================================="
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

# Step 1 — find employer(s) by name + location
$nameEsc = [uri]::EscapeDataString($EmployerName)
$locEsc  = [uri]::EscapeDataString($Location)

$selectCols = "id,employer_name,location,contact_status,last_contacted_at,notes_internal"

$queryUri = "$SupabaseUrl/rest/v1/reachx_employers?select=$selectCols&employer_name=eq.$nameEsc&location=eq.$locEsc"

Write-Host "Looking up employer(s)..."
Write-Host ("  {0}" -f $queryUri)
Write-Host ""

$rows = Invoke-RestMethod -Uri $queryUri -Headers $headers -Method Get

if (-not $rows -or $rows.Count -eq 0) {
    Write-Host ("No employers found for name='{0}' location='{1}'." -f $EmployerName, $Location)
    return
}

Write-Host ("Found {0} employer record(s)." -f $rows.Count)

$nowUtc   = (Get-Date).ToUniversalTime()
$nowIso   = $nowUtc.ToString("o")
$noteLine = "[{0} UTC][{1}] {2}" -f $nowUtc.ToString("yyyy-MM-dd HH:mm"), $Channel, $Note

$updatedCount = 0

foreach ($row in $rows) {
    $id             = $row.id
    $existingNotes  = $row.notes_internal
    $combinedNotes  = $null

    if ($existingNotes) {
        $combinedNotes = $existingNotes + "`n" + $noteLine
    }
    else {
        $combinedNotes = $noteLine
    }

    $payload = @{
        contact_status    = $Status
        last_contacted_at = $nowIso
        notes_internal    = $combinedNotes
    }

    $json = $payload | ConvertTo-Json -Depth 5
    $body = "[$json]"

    $patchUri = "$SupabaseUrl/rest/v1/reachx_employers?id=eq.$id"

    try {
        $result = Invoke-RestMethod -Uri $patchUri -Headers $headers -Method Patch -Body $body
        $updatedCount++
        Write-Host ("Updated employer id={0} name='{1}' location='{2}' -> status='{3}'" -f `
            $id, $row.employer_name, $row.location, $Status)
    }
    catch {
        Write-Host ("ERROR updating employer id={0}: {1}" -f $id, $_.Exception.Message)
    }
}

Write-Host ""
Write-Host ("Done. Updated {0} employer record(s)." -f $updatedCount)
