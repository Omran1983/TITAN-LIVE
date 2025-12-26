$SupabaseUrl = "https://drnqpbyptyyuacmrvdrr.supabase.co"
$SecretFile  = "F:\AION-ZERO\secrets\educonnect-service-role-key.txt"

if (-not (Test-Path $SecretFile)) {
    Write-Host "[ERROR] Secret file not found: $SecretFile" -ForegroundColor Red
    return
}

$SupabaseKey = (Get-Content $SecretFile -Raw).Trim()

if ([string]::IsNullOrWhiteSpace($SupabaseKey)) {
    Write-Host "[ERROR] Secret file is empty: $SecretFile" -ForegroundColor Red
    return
}

$headers = @{
    apikey         = $SupabaseKey
    Authorization  = "Bearer $SupabaseKey"
    "Content-Type" = "application/json"
}

function Show-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
}

# 1) Enrollment summary per course (view: enrollment_summary)
Show-Section "Enrollments per course (enrollment_summary)"

try {
    $uriSummary = "$SupabaseUrl/rest/v1/enrollment_summary?select=*"
    $summary = Invoke-RestMethod -Uri $uriSummary -Headers $headers -Method Get

    if (-not $summary) {
        Write-Host "No data in enrollment_summary yet." -ForegroundColor Yellow
    }
    else {
        $summary |
            Select-Object course, total_enrollments, new_enrollments, first_enrollment_at, latest_enrollment_at |
            Format-Table -AutoSize
    }
}
catch {
    Write-Host "[WARN] enrollment_summary not available yet. Did you run the SQL view creation?" -ForegroundColor Yellow
    Write-Host $_.Exception.Message
    if ($_.ErrorDetails) { Write-Host $_.ErrorDetails }
}

# 2) Enrollment status distribution (group in PowerShell)
Show-Section "Enrollment status distribution"

try {
    $uriStatus = "$SupabaseUrl/rest/v1/enrollments?select=status&order=status"
    $rows = Invoke-RestMethod -Uri $uriStatus -Headers $headers -Method Get

    if (-not $rows) {
        Write-Host "No enrollments found." -ForegroundColor Yellow
    }
    else {
        $rows |
            Group-Object -Property status |
            Select-Object @{Name='status';Expression={$_.Name}},
                          @{Name='count'; Expression={$_.Count}} |
            Sort-Object status |
            Format-Table -AutoSize
    }
}
catch {
    Write-Host "[ERROR] Failed to compute status breakdown:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    if ($_.ErrorDetails) { Write-Host $_.ErrorDetails }
}

# 3) Last 5 enrollments
Show-Section "Last 5 enrollments"

try {
    $uriLast = "$SupabaseUrl/rest/v1/enrollments" +
               "?select=id,full_name,email,phone,course,source,status,created_at" +
               "&order=created_at.desc&limit=5"

    $rows = Invoke-RestMethod -Uri $uriLast -Headers $headers -Method Get

    if (-not $rows) {
        Write-Host "No enrollments yet." -ForegroundColor Yellow
    }
    else {
        $rows |
            Select-Object id, full_name, course, source, status, created_at |
            Format-Table -AutoSize
    }
}
catch {
    Write-Host "[ERROR] Failed to fetch last enrollments:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    if ($_.ErrorDetails) { Write-Host $_.ErrorDetails }
}
