param(
    [string]$Environment   = "dev",
    [int]$MinCpuScore      = 8,
    [int]$MinMemoryScore   = 8,
    [string]$CommandText   = $(throw "CommandText is required.")
)

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Error "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set."
    exit 1
}

$baseUrl = $env:SUPABASE_URL.Trim()
$baseUrl = $baseUrl -replace "/+$",""
$apiKey  = $env:SUPABASE_SERVICE_ROLE_KEY

$jobsUrl = "$baseUrl/rest/v1/system_remote_jobs"

# 1) Pick best machine
$selectorScript = "F:\ReachX-AI\scripts\ReachX-Select-MachineForJob.ps1"
if (-not (Test-Path $selectorScript)) {
    Write-Error "Selector script not found at $selectorScript"
    exit 1
}

$bestMachine = & $selectorScript -Environment $Environment -MinCpuScore $MinCpuScore -MinMemoryScore $MinMemoryScore

if (-not $bestMachine) {
    Write-Error "No eligible machine returned by selector."
    exit 1
}

Write-Host "✅ Selected target machine: $bestMachine" -ForegroundColor Green

# 2) Build job payload
$payload = @(
    [PSCustomObject]@{
        environment         = $Environment
        machine_name_target = $bestMachine
        command_type        = "powershell"
        command_text        = $CommandText
        status              = "queued"
        requested_by        = "omran"
        cpu_min             = $MinCpuScore
        mem_min             = $MinMemoryScore
    }
)

$jsonBody = $payload | ConvertTo-Json -Depth 5

$headers = @{
    "apikey"        = $apiKey
    "Authorization" = "Bearer $apiKey"
    "Content-Type"  = "application/json"
    "Prefer"        = "return=representation"
}

try {
    $resp = Invoke-RestMethod -Method Post -Uri $jobsUrl -Headers $headers -Body $jsonBody -ErrorAction Stop
    Write-Host "✅ Remote job created in Supabase:" -ForegroundColor Green
    $resp | Format-Table id, machine_name_target, status, created_at
} catch {
    Write-Error "Failed to submit remote job: $_"
    Write-Host "Request body was:" -ForegroundColor DarkGray
    Write-Host $jsonBody
    exit 1
}
