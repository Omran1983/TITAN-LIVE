param(
    [string]$SupabaseUrl = $env:REACHX_SUPABASE_URL,
    [string]$SupabaseKey = $env:REACHX_SUPABASE_SERVICE_KEY
)

if (-not $SupabaseUrl -or -not $SupabaseKey) {
    Write-Host "Set Supabase URL + Service Key first:" -ForegroundColor Yellow
    Write-Host '$env:REACHX_SUPABASE_URL         = "https://YOURPROJECTID.supabase.co"' -ForegroundColor Yellow
    Write-Host '$env:REACHX_SUPABASE_SERVICE_KEY = "<service_role_key>"' -ForegroundColor Yellow
    return
}

$SupabaseUrl = $SupabaseUrl.TrimEnd("/")

$endpoint = "$SupabaseUrl/rest/v1/dormitories?select=name,city,area,country,capacity_total,capacity_occupied,gender,owner_name,contact_phone,contact_email,notes&order=created_at.desc&limit=50"

$headers = @{
    apikey        = $SupabaseKey
    Authorization = "Bearer $SupabaseKey"
}

Write-Host "Fetching dormitories snapshot from: $endpoint" -ForegroundColor Cyan

try {
    $resp = Invoke-RestMethod -Uri $endpoint -Headers $headers -Method Get
}
catch {
    Write-Host "Error calling Supabase (dormitories): $($_.Exception.Message)" -ForegroundColor Red
    return
}

if (-not $resp) {
    Write-Host "No dormitories returned." -ForegroundColor Yellow
    return
}

$resp |
    Select-Object `
        name,
        city,
        area,
        country,
        capacity_total,
        capacity_occupied,
        gender,
        owner_name,
        contact_phone |
    Format-Table -AutoSize
