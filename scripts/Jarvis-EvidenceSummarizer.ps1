param(
    [Parameter(Mandatory = $true)]
    [int]$SourceId
)

Write-Host "=== Jarvis-EvidenceSummarizer ===" -ForegroundColor Cyan

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

# 1) Fetch source to get project
$srcUrl = "$baseUrl/rest/v1/az_knowledge_sources?id=eq.$SourceId&select=id,project&limit=1"
Write-Host "Source URL: $srcUrl" -ForegroundColor DarkGray

try {
    $srcResp = Invoke-RestMethod -Method Get -Uri $srcUrl -Headers $headers
} catch {
    Write-Host ("ERROR - Failed to fetch az_knowledge_sources: {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}

if (-not $srcResp) {
    Write-Host "ERROR - No az_knowledge_sources row found for id=$SourceId." -ForegroundColor Red
    exit 1
}

$source = if ($srcResp -is [System.Array]) { $srcResp[0] } else { $srcResp }
$project = $source.project
Write-Host ("Found source id={0} project={1}" -f $source.id, $project) -ForegroundColor Green

# 2) Fetch all chunks for this source_id
$chunksUrl = "$baseUrl/rest/v1/az_knowledge_chunks" +
             "?select=chunk_index,content" +
             "&source_id=eq.$SourceId" +
             "&order=chunk_index.asc"

Write-Host "Chunks URL: $chunksUrl" -ForegroundColor DarkGray

try {
    $chunksResp = Invoke-RestMethod -Method Get -Uri $chunksUrl -Headers $headers
} catch {
    Write-Host ("ERROR - Failed to fetch az_knowledge_chunks: {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}

if (-not $chunksResp -or $chunksResp.Count -eq 0) {
    Write-Host "No chunks found for this source_id. Nothing to summarize." -ForegroundColor Yellow
    exit 0
}

$chunks = if ($chunksResp -is [System.Array]) { $chunksResp } else { @($chunksResp) }
Write-Host ("Fetched {0} chunks." -f $chunks.Count) -ForegroundColor Green

# 3) Build naive evidence summary (concat all chunk contents)
$allTextParts = @()

foreach ($c in $chunks | Sort-Object chunk_index) {
    $text = [string]$c.content
    if ($text.Trim().Length -gt 0) {
        $allTextParts += $text.Trim()
    }
}

if ($allTextParts.Count -eq 0) {
    Write-Host "All chunks were empty after trimming. Nothing to summarize." -ForegroundColor Yellow
    exit 0
}

$combined = [string]::Join("`n`n", $allTextParts)

# Hard cap to keep it reasonable
$maxLen = 8000
if ($combined.Length -gt $maxLen) {
    $combined = $combined.Substring(0, $maxLen) + "`n`n...[TRUNCATED]"
}

Write-Host ("Combined summary length: {0} characters" -f $combined.Length) -ForegroundColor DarkGray

# 4) Insert into az_knowledge_cards
$cardsUrl = "$baseUrl/rest/v1/az_knowledge_cards"
$title    = "Evidence card for source $SourceId"

$bodyObj = @{
    source_id = $SourceId
    project   = $project
    title     = $title
    summary   = $combined
}

$bodyJson = $bodyObj | ConvertTo-Json -Depth 5
Write-Host "POST $cardsUrl" -ForegroundColor DarkGray
Write-Host "Body (truncated preview):" -ForegroundColor DarkGray
if ($combined.Length -gt 300) {
    Write-Host ($bodyJson.Substring(0, 300) + "...") -ForegroundColor DarkGray
} else {
    Write-Host $bodyJson -ForegroundColor DarkGray
}

try {
    $resp = Invoke-RestMethod -Method Post -Uri $cardsUrl -Headers $headers -Body $bodyJson
    Write-Host "Evidence card inserted into az_knowledge_cards." -ForegroundColor Green
} catch {
    Write-Host ("ERROR - Failed to insert into az_knowledge_cards: {0}" -f $_.Exception.Message) -ForegroundColor Red
    if ($_.Exception.Response -and $_.Exception.Response.GetResponseStream()) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "ERROR response body: $responseBody" -ForegroundColor Red
    }
    exit 1
}

Write-Host "=== Jarvis-EvidenceSummarizer end ===" -ForegroundColor Cyan
