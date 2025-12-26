# ReachX-Report-MachineProfile-ToSupabase.ps1
# Reads WinSAT hardware scores and pushes them to Supabase table system_machine_profiles

param(
    [string]$Environment = "dev"  # dev / prod / lab etc.
)

# 1) Check env vars
if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Error "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set in environment."
    exit 1
}

$baseUrl   = $env:SUPABASE_URL.TrimEnd("/")
$apiUrl    = "$baseUrl/rest/v1/system_machine_profiles"
$apiKey    = $env:SUPABASE_SERVICE_ROLE_KEY

# 2) Get WinSAT data
try {
    $ws = Get-WmiObject -Class Win32_WinSAT -ErrorAction Stop
} catch {
    Write-Error "Failed to read WinSAT data: $_"
    exit 1
}

$machineName = $env:COMPUTERNAME

# 3) Build payload object
$payload = @(
    [PSCustomObject]@{
        machine_name    = $machineName
        environment     = $Environment
        cpu_score       = $ws.CPUScore
        memory_score    = $ws.MemoryScore
        disk_score      = $ws.DiskScore
        graphics_score  = $ws.GraphicsScore
        d3d_score       = $ws.D3DScore
        winspr_level    = $ws.WinSPRLevel
        raw_payload     = @{
            TimeTaken             = $ws.TimeTaken
            WinSATAssessmentState = $ws.WinSATAssessmentState
        }
        collected_at    = (Get-Date).ToString("o")
    }
)

$jsonBody = $payload | ConvertTo-Json -Depth 5

# 4) POST to Supabase
$headers = @{
    "apikey"        = $apiKey
    "Authorization" = "Bearer $apiKey"
    "Content-Type"  = "application/json"
    "Prefer"        = "return=representation"
}

try {
    $response = Invoke-RestMethod -Method Post -Uri $apiUrl -Headers $headers -Body $jsonBody -ErrorAction Stop
    Write-Host "✅ Machine profile sent to Supabase:"
    $response | Format-Table id, machine_name, environment, cpu_score, memory_score, winspr_level
} catch {
    Write-Error "Failed to send profile to Supabase: $_"
    Write-Host "Request body was:" -ForegroundColor DarkGray
    Write-Host $jsonBody
    exit 1
}
