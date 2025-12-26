param(
    [string]$Environment   = "dev",
    [int]$MinCpuScore      = 8,
    [int]$MinMemoryScore   = 8
)

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Error "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set."
    exit 1
}

# Clean and normalize base URL
$baseUrl = $env:SUPABASE_URL.Trim()
$baseUrl = $baseUrl -replace "/+$",""

$apiUrl  = "$baseUrl/rest/v1/system_machine_profiles_latest"
$apiKey  = $env:SUPABASE_SERVICE_ROLE_KEY

Write-Host "DEBUG baseUrl: [$baseUrl]" -ForegroundColor DarkGray
Write-Host "DEBUG apiUrl : [$apiUrl]"  -ForegroundColor DarkGray

try {
    [void][uri]$apiUrl
} catch {
    Write-Error "Constructed API URL is invalid: [$apiUrl] -> $_"
    exit 1
}

$headers = @{
    "apikey"        = $apiKey
    "Authorization" = "Bearer $apiKey"
}

$uriWithQuery = "${apiUrl}?environment=eq.${Environment}&order=winspr_level.desc"
Write-Host "DEBUG final URI: [$uriWithQuery]" -ForegroundColor DarkGray

try {
    $machines = Invoke-RestMethod -Method Get -Uri $uriWithQuery -Headers $headers -ErrorAction Stop
} catch {
    Write-Error "Failed to query Supabase for machines: $_"
    exit 1
}

if (-not $machines -or $machines.Count -eq 0) {
    Write-Error "No machines found for environment '$Environment'."
    return
}

$eligible = $machines | Where-Object {
    ($_."cpu_score"    -ge $MinCpuScore) -and
    ($_."memory_score" -ge $MinMemoryScore)
}

if (-not $eligible -or $eligible.Count -eq 0) {
    Write-Error "No machines meet minimum CPU=$MinCpuScore and Memory=$MinMemoryScore."
    Write-Host "Available machines:" -ForegroundColor DarkGray
    $machines | Format-Table machine_name, environment, cpu_score, memory_score, winspr_level | Out-Host
    return
}

$selected = $eligible | Sort-Object -Property winspr_level -Descending | Select-Object -First 1

Write-Host "✅ Selected machine for job:" -ForegroundColor Green
$selected | Format-Table machine_name, environment, cpu_score, memory_score, disk_score, winspr_level | Out-Host

# IMPORTANT: only output the machine name to the pipeline
return $selected.machine_name
