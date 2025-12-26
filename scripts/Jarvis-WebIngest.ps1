param(
    [Parameter(Mandatory = $true)]
    [string]$Project,   # e.g. 'AION-ZERO'

    [Parameter(Mandatory = $true)]
    [string]$Url        # e.g. 'https://example.com/article'
)

Write-Host "=== Jarvis-WebIngest ===" -ForegroundColor Cyan

# Resolve script dir
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir  = Split-Path -Parent $scriptPath

# 1) Load env
$envLoader = Join-Path $scriptDir "Jarvis-LoadEnv.ps1"
if (-not (Test-Path $envLoader)) {
    Write-Host "ERROR: Jarvis-LoadEnv.ps1 not found at $envLoader" -ForegroundColor Red
    exit 1
}
. $envLoader
Write-Host "Loaded environment from Jarvis-LoadEnv.ps1." -ForegroundColor DarkGray

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY missing." -ForegroundColor Red
    exit 1
}

$baseUrl = $env:SUPABASE_URL.Trim().TrimEnd('/')

$headers = @{
    apikey         = $env:SUPABASE_SERVICE_ROLE_KEY
    Authorization  = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    Accept         = "application/json"
    "Content-Type" = "application/json"
    Prefer         = "return=representation"
}

# 2) Fetch page
Write-Host "Fetching URL: $Url" -ForegroundColor DarkGray
try {
    $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Host "ERROR: Failed to fetch URL: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__) {
        $code = $_.Exception.Response.StatusCode.value__
        Write-Host "HTTP status code: $code" -ForegroundColor DarkRed
        if ($code -eq 999) {
            Write-Host "NOTE: This site is actively blocking scripted/automated access (e.g. LinkedIn anti-bot)." -ForegroundColor Yellow
        }
    }
    exit 1
}

# 3) Extract plain text from raw HTML
$rawHtml = $resp.Content
if ([string]::IsNullOrWhiteSpace($rawHtml)) {
    Write-Host "ERROR: Response content is empty." -ForegroundColor Red
    exit 1
}

# Remove script and style blocks
$noScripts = [regex]::Replace($rawHtml, "<script[^>]*?>.*?</script>", "", "Singleline,IgnoreCase")
$noStyles  = [regex]::Replace($noScripts, "<style[^>]*?>.*?</style>", "", "Singleline,IgnoreCase")

# Strip all remaining HTML tags
$noTags = [regex]::Replace($noStyles, "<[^>]+>", " ")

# Normalize whitespace
$text = [regex]::Replace($noTags, "\s+", " ").Trim()

if ([string]::IsNullOrWhiteSpace($text)) {
    Write-Host "ERROR: Could not extract text from page (empty after cleanup)." -ForegroundColor Red
    exit 1
}

Write-Host ("Extracted text length: {0} characters" -f $text.Length) -ForegroundColor DarkGray

# 3b) Page title (best effort)
$title = $null
try {
    if ($resp.ParsedHtml -and $resp.ParsedHtml.title) {
        $title = $resp.ParsedHtml.title
    }
} catch {
    $title = $null
}
if (-not $title) { $title = $Url }

# 4) Upsert into az_knowledge_sources
$sourceUrl = "$baseUrl/rest/v1/az_knowledge_sources?on_conflict=project,source_key"

$sourceBodyObj = [ordered]@{
    project     = $Project
    source_type = "url"
    source_key  = $Url
    title       = $title
}

$sourceBodyJson = $sourceBodyObj | ConvertTo-Json -Depth 5
Write-Host "Upserting knowledge source..." -ForegroundColor DarkGray

try {
    $sourceResp = Invoke-RestMethod -Method Post -Uri $sourceUrl -Headers $headers -Body $sourceBodyJson -ErrorAction Stop
} catch {
    Write-Host "ERROR: Failed to upsert az_knowledge_sources: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
        Write-Host "DETAILS: $($_.ErrorDetails.Message)" -ForegroundColor DarkRed
    }
    exit 1
}

if (-not $sourceResp -or $sourceResp.Count -eq 0) {
    Write-Host "ERROR: No source row returned from Supabase (expected representation)." -ForegroundColor Red
    exit 1
}

$sourceId = $sourceResp[0].id
Write-Host "Source ID = $sourceId (project=$Project, url=$Url)" -ForegroundColor Green

# 5) Split into chunks (e.g. 1000 chars per chunk)
$maxChunkSize = 1000
$chunks = @()

for ($offset = 0; $offset -lt $text.Length; $offset += $maxChunkSize) {
    $length    = [Math]::Min($maxChunkSize, $text.Length - $offset)
    $chunkText = $text.Substring($offset, $length).Trim()
    if (-not [string]::IsNullOrWhiteSpace($chunkText)) {
        $chunks += $chunkText
    }
}

Write-Host ("Prepared {0} chunks." -f $chunks.Count) -ForegroundColor DarkGray

if ($chunks.Count -eq 0) {
    Write-Host "ERROR: No non-empty chunks produced." -ForegroundColor Red
    exit 1
}

# 6) Insert chunks into az_knowledge_chunks
$chunksUrl = "$baseUrl/rest/v1/az_knowledge_chunks"

$chunkIndex = 0
foreach ($chunk in $chunks) {
    $chunkObj = [ordered]@{
        source_id   = $sourceId
        chunk_index = $chunkIndex
        content     = $chunk
    }

    $chunkJson = $chunkObj | ConvertTo-Json -Depth 5

    try {
        Invoke-RestMethod -Method Post -Uri $chunksUrl -Headers $headers -Body $chunkJson -ErrorAction Stop | Out-Null
        Write-Host ("Inserted chunk #{0}" -f $chunkIndex) -ForegroundColor DarkGray
    } catch {
        Write-Host ("ERROR: Failed to insert chunk #{0}: {1}" -f $chunkIndex, $_.Exception.Message) -ForegroundColor Red
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            Write-Host "DETAILS: $($_.ErrorDetails.Message)" -ForegroundColor DarkRed
        }
        # continue to next chunk
    }

    $chunkIndex++
}

Write-Host "=== Jarvis-WebIngest end (success) ===" -ForegroundColor Cyan
