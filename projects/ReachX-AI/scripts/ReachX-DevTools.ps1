[CmdletBinding()]
param()

$Root = "F:\ReachX-AI"
$ScriptsDir = Join-Path $Root "scripts"
$DataDir = Join-Path $Root "data"

function Invoke-ReachXAgentHarvest {
    <#
        Harvests Mauritius IFC employers, ingests into Supabase,
        and refreshes ReachX UI via Run-AgentPipeline.ps1
    #>
    Write-Host "=== Invoke-ReachXAgentHarvest ===" -ForegroundColor Cyan
    Push-Location $ScriptsDir
    try {
        .\Run-AgentPipeline.ps1
    }
    finally {
        Pop-Location
    }
}

function Invoke-ReachXConstructionHarvest {
    <#
        Runs the 4-step construction pipeline:
        1) construction_scraper.py
        2) dedupe_construction.py
        3) enrich_construction.py
        4) ReachX-Refresh-All.ps1
    #>
    Write-Host "=== Invoke-ReachXConstructionHarvest ===" -ForegroundColor Cyan
    Push-Location $ScriptsDir
    try {
        .\Run-Construction-Pipeline.ps1
    }
    finally {
        Pop-Location
    }
}

function Show-ReachXEmployersCsv {
    <#
        Quick view of harvested employers from the raw CSV
    #>
    $csvPath = Join-Path $DataDir "raw\employers_mauritiusifc.csv"
    if (-not (Test-Path $csvPath)) {
        Write-Warning "CSV not found at $csvPath"
        return
    }

    Write-Host "=== ReachX Employers (from CSV) ===" -ForegroundColor Cyan
    Import-Csv $csvPath |
        Select-Object -First 30
}

function Show-ReachXEmployersFromSupabase {
    <#
        Fetches employers from Supabase reachx_employers via REST API
        Requires:
          REACHX_SUPABASE_URL
          REACHX_SUPABASE_SERVICE_KEY  (service role key)
    #>
    if (-not $env:REACHX_SUPABASE_URL -or -not $env:REACHX_SUPABASE_SERVICE_KEY) {
        Write-Warning "REACHX_SUPABASE_URL or REACHX_SUPABASE_SERVICE_KEY not set in env."
        return
    }

    $url = "$($env:REACHX_SUPABASE_URL)/rest/v1/reachx_employers?select=*"
    $headers = @{
        apikey        = $env:REACHX_SUPABASE_SERVICE_KEY
        Authorization = "Bearer $($env:REACHX_SUPABASE_SERVICE_KEY)"
    }

    Write-Host "=== ReachX Employers (from Supabase) ===" -ForegroundColor Cyan
    try {
        $rows = Invoke-RestMethod -Method Get -Uri $url -Headers $headers
        $rows |
            Select-Object -First 30 `
                employer_name,
                sector,
                industry,
                country,
                email,
                phone,
                source
    }
    catch {
        Write-Error "Failed to fetch from Supabase: $($_.Exception.Message)"
    }
}
