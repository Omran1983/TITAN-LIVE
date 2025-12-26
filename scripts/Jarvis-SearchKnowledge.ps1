param(
    [Parameter(Mandatory = $true)]
    [string]$Query
)

Write-Host "=== Jarvis-SearchKnowledge ===" -ForegroundColor Cyan

# Resolve script directory
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir  = Split-Path -Parent $scriptPath
Write-Host "ScriptDir: $scriptDir" -ForegroundColor DarkGray

# Load environment
$envScript = Join-Path $scriptDir "Jarvis-LoadEnv.ps1"
if (Test-Path $envScript) {
    . $envScript
    Write-Host "Loaded environment from Jarvis-LoadEnv.ps1." -ForegroundColor DarkGray
} else {
    Write-Host "ERROR - Jarvis-LoadEnv.ps1 not found at $envScript" -ForegroundColor Red
    exit 1
}

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "ERROR - SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is not set in environment." -ForegroundColor Red
    exit 1
}

$baseUrl    = $env:SUPABASE_URL.TrimEnd('/')
$serviceKey = $env:SUPABASE_SERVICE_ROLE_KEY

$headers = @{
    apikey         = $serviceKey
    Authorization  = "Bearer $serviceKey"
    Accept         = "application/json"
    "Content-Type" = "application/json"
}

# Prepare search term
$term = $Query.Trim()
if (-not $term) {
    Write-Host "ERROR - Empty query string." -ForegroundColor Red
    exit 1
}

# naive URL encoding for spaces; good enough for now
$encodedTerm = $term -replace ' ', '%20'

# We search directly in az_knowledge_chunks.content
# NOTE: this does NOT depend on any specific columns in az_knowledge_sources.
$chunksUrl = "$baseUrl/rest/v1/az_knowledge_chunks" +
             "?select=id,source_id,chunk_index,content" +
             "&content=ilike.*$encodedTerm*" +
             "&order=source_id,chunk_index" +
             "&limit=20"

Write-Host "Chunks URL: $chunksUrl" -ForegroundColor DarkGray
Write-Host "Searching for: '$term'" -ForegroundColor Cyan

try {
    $resp = Invoke-RestMethod -Method Get -Uri $chunksUrl -Headers $headers
} catch {
    Write-Host ("ERROR - Failed to search knowledge chunks: {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}

if (-not $resp -or $resp.Count -eq 0) {
    Write-Host "No matches found in az_knowledge_chunks." -ForegroundColor Yellow
    exit 0
}

# Normalize to array
$chunks = if ($resp -is [System.Array]) { $resp } else { @($resp) }

Write-Host ""
Write-Host ("=== Search Results (top {0}) ===" -f $chunks.Count) -ForegroundColor Green

# Group by source_id for readability
$grouped = $chunks | Group-Object source_id | Sort-Object Name

foreach ($g in $grouped) {
    $sid = $g.Name
    Write-Host ""
    Write-Host ("--- Source ID: {0} ---" -f $sid) -ForegroundColor Magenta

    foreach ($c in ($g.Group | Sort-Object chunk_index)) {
        $preview = [string]$c.content
        if ($preview.Length -gt 200) {
            $preview = $preview.Substring(0, 200) + "..."
        }

        Write-Host ("[chunk {0}] {1}" -f $c.chunk_index, $preview) -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== Jarvis-SearchKnowledge end ===" -ForegroundColor Cyan
