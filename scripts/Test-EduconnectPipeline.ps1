$SupabaseUrl = "https://drnqpbyptyyuacmrvdrr.supabase.co"
$WorkerUrl   = "https://educonnect-hq-lite.dubsy1983-51e.workers.dev/enroll"
$LogDir      = "F:\EduConnect\logs"
$SecretFile  = "F:\AION-ZERO\secrets\educonnect-service-role-key.txt"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$logFile = Join-Path $LogDir ("EduconnectPipeline-" + (Get-Date -Format "yyyyMMdd") + ".log")

function Write-Log {
    param([string]$Message)
    $stamp = Get-Date -Format "s"
    $line  = "[${stamp}] $Message"
    $line | Out-File -FilePath $logFile -Append -Encoding UTF8
    Write-Host $line
}

# Load SERVICE_ROLE key: env var first, then secret file, NO PROMPT (for scheduled tasks)
if (-not $env:EDUCONNECT_SUPABASE_SERVICE_ROLE_KEY -or
    [string]::IsNullOrWhiteSpace($env:EDUCONNECT_SUPABASE_SERVICE_ROLE_KEY)) {

    if (Test-Path $SecretFile) {
        $env:EDUCONNECT_SUPABASE_SERVICE_ROLE_KEY = (Get-Content $SecretFile -Raw).Trim()
        Write-Log "Loaded SERVICE_ROLE key from secret file."
    }
    else {
        Write-Log "ERROR: SERVICE_ROLE key missing. Secret file not found: $SecretFile"
        return
    }
}

$SupabaseKey = $env:EDUCONNECT_SUPABASE_SERVICE_ROLE_KEY

Write-Log "=== STEP 1: Worker /enroll → Supabase ==="

$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$workerBodyObject = @{
    full_name = "Pipeline Test $ts"
    course    = "AI Workshop"
    phone     = "2309999999"
    notes     = "Pipeline health check via Test-EduconnectPipeline.ps1"
    source    = "pipeline-test"
    email     = "pipeline-test@example.com"
}
$workerBody = $workerBodyObject | ConvertTo-Json -Depth 5

Write-Log "POST $WorkerUrl"
Write-Log $workerBody

try {
    $workerResp = Invoke-RestMethod -Uri $WorkerUrl -Method Post -Body $workerBody -Headers @{
        "Content-Type" = "application/json"
        "Accept"       = "application/json"
    }

    Write-Log "Worker /enroll OK:"
    ($workerResp | ConvertTo-Json -Depth 5) | Out-File -FilePath $logFile -Append -Encoding UTF8
}
catch {
    Write-Log "Worker /enroll FAILED: $($_.Exception.Message)"
    if ($_.ErrorDetails) {
        Write-Log ("Worker error body: " + $_.ErrorDetails)
    }
    return
}

Write-Log "=== STEP 2: Fetch latest enrollments from Supabase ==="

$headers = @{
    apikey         = $SupabaseKey
    Authorization  = "Bearer $SupabaseKey"
    "Content-Type" = "application/json"
}

$uri = "$SupabaseUrl/rest/v1/enrollments?select=*&order=created_at.desc&limit=5"

Write-Log "GET $uri"

try {
    $rows = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers

    if (-not $rows) {
        Write-Log "No enrollments found."
        return
    }

    $table = $rows |
        Select-Object id, full_name, email, phone, course, source, status, created_at |
        Format-Table -AutoSize | Out-String

    $table | Out-File -FilePath $logFile -Append -Encoding UTF8
    Write-Host $table
}
catch {
    Write-Log "Failed to fetch enrollments: $($_.Exception.Message)"
    if ($_.ErrorDetails) {
        Write-Log ("Supabase error body: " + $_.ErrorDetails)
    }
}
