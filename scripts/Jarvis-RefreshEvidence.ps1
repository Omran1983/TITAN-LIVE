param(
    [string]$Project = ""  # e.g. "AION-ZERO" (empty = all projects)
)

Write-Host "=== Jarvis-RefreshEvidence starting ==="

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ScriptDir

Write-Host "[RefreshEvidence] ScriptDir = $ScriptDir"
Write-Host "[RefreshEvidence] RootDir   = $RootDir"

# 1) Load environment
& "$ScriptDir\Jarvis-LoadEnv.ps1"

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "[RefreshEvidence] ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set. Exiting."
    exit 1
}

$baseUrl    = $env:SUPABASE_URL.TrimEnd('/')
$serviceKey = $env:SUPABASE_SERVICE_ROLE_KEY

$headers = @{
    apikey        = $serviceKey
    Authorization = "Bearer $serviceKey"
    Accept        = "application/json"
}

# 2) Build URL to fetch all sources
if ([string]::IsNullOrWhiteSpace($Project)) {
    $filter = "select=id,project,source_key&order=id.asc"
} else {
    $filter = "project=eq.$Project&select=id,project,source_key&order=id.asc"
}

$uri = "$baseUrl/rest/v1/az_knowledge_sources?$filter"

Write-Host "[RefreshEvidence] Fetching sources from: $uri"

try {
    $sources = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
}
catch {
    Write-Host "[RefreshEvidence] ERROR: Failed to fetch az_knowledge_sources"
    Write-Host "[RefreshEvidence] Exception: $($_.Exception.Message)"
    exit 1
}

if (-not $sources -or $sources.Count -eq 0) {
    Write-Host "[RefreshEvidence] No sources found. Exiting."
    exit 0
}

Write-Host "[RefreshEvidence] Found $($sources.Count) source(s)."

foreach ($src in $sources) {
    $id      = $src.id
    $project = $src.project
    $key     = $src.source_key

    Write-Host ">>> Refreshing evidence for source_id=$id (project=$project, key=$key)"

    try {
        powershell -NoProfile -ExecutionPolicy Bypass -File `
            "$ScriptDir\Jarvis-EvidenceSummarizer.ps1" `
            -SourceId $id
    }
    catch {
        Write-Host "[RefreshEvidence] ERROR: Summarizer failed for source_id=$id"
        Write-Host "[RefreshEvidence] Exception: $($_.Exception.Message)"
        # Continue with other sources
    }
}

Write-Host "=== Jarvis-RefreshEvidence finished ==="
