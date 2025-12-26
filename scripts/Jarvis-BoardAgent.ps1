param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# paths and logging
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$root       = Split-Path -Parent $scriptRoot
$logDir     = Join-Path $root "logs"
New-Item -ItemType Directory -Path $logDir -ErrorAction SilentlyContinue | Out-Null
$logPath    = Join-Path $logDir "BoardAgent.log"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$ts [$Level] $Message"
    $line | Tee-Object -FilePath $logPath -Append | Out-Host
}

Write-Log "=== Jarvis-BoardAgent START ==="

try {
    # env + supabase
    $envFile = Join-Path $root ".env"
    $loader  = Join-Path $scriptRoot "Load-DotEnv.ps1"
    if (-not (Test-Path $loader)) {
        throw "Load-DotEnv.ps1 not found at $loader"
    }
    & $loader -EnvFilePath $envFile

    $supabaseUrl  = $env:SUPABASE_URL
    $serviceKey   = $env:SUPABASE_SERVICE_KEY

    if ([string]::IsNullOrWhiteSpace($supabaseUrl) -or
        [string]::IsNullOrWhiteSpace($serviceKey)) {
        throw "Missing SUPABASE_URL or SUPABASE_SERVICE_KEY in environment."
    }

    $headers = @{
        apikey        = $serviceKey
        Authorization = "Bearer " + $serviceKey
        "Content-Type" = "application/json"
        Prefer        = "return=representation"
    }

    $endpoint   = $supabaseUrl + "/rest/v1/az_director_snapshots"
    $todayLabel = (Get-Date).ToString("yyyy-MM-dd")

    function New-DirectorSnapshot {
        param(
            [string]$Director,
            [string]$Mission,
            [string]$Vision,
            [string]$StatusText,
            [string]$BlockersText,
            [string]$ImprovementsText,
            [string]$EtaText,
            [hashtable]$Meta
        )

        $bodyObj = @{
            director          = $Director
            mission           = $Mission
            vision            = $Vision
            status_text       = $StatusText
            blockers_text     = $BlockersText
            improvements_text = $ImprovementsText
            eta_text          = $EtaText
            meta              = $Meta
        }

        $jsonBody = $bodyObj | ConvertTo-Json -Depth 5
        Write-Log ("Posting snapshot for {0}..." -f $Director)
        $resp = Invoke-RestMethod -Method Post -Uri $endpoint -Headers $headers -Body $jsonBody
        Write-Log ("Snapshot stored for {0}" -f $Director)
    }

    # -------- ATLAS (Automation) --------------------------------------
    $mission = "Build and maintain a self running automation layer."
    $vision  = "Automation handles recurring technical work instead of the CEO."
    $status  = "Automation backbone is partly wired. CommandAgent, DbDump, and BoardAgent are online."
    $block   = "No unified automation health dashboard yet. Alerts are not wired."
    $improv  = "Connect scheduled task health, Supabase checks, and error alerts into one simple view."
    $eta     = "Basic automation health report within 30 days."

    New-DirectorSnapshot -Director "ATLAS" `
        -Mission $mission -Vision $vision `
        -StatusText $status -BlockersText $block `
        -ImprovementsText $improv -EtaText $eta `
        -Meta @{ date = $todayLabel; reporter = "BoardAgent"; domain = "Automation" }

    # -------- VEGA (Commerce) ----------------------------------------
    $mission = "Turn AOGRL products into predictable revenue engines."
    $vision  = "Daily and weekly revenue cycles running mostly on autopilot."
    $status  = "OKASINA and other deals exist, but live revenue metrics and funnels are not fully wired."
    $block   = "No central revenue dashboard. No automatic daily summary of orders or cash in."
    $improv  = "Wire orders and deals into a daily revenue summary and simple weekly trend view."
    $eta     = "First daily revenue summary within 14 days."

    New-DirectorSnapshot -Director "VEGA" `
        -Mission $mission -Vision $vision `
        -StatusText $status -BlockersText $block `
        -ImprovementsText $improv -EtaText $eta `
        -Meta @{ date = $todayLabel; reporter = "BoardAgent"; domain = "Commerce" }

    # -------- ORION (ReachX / Talent) --------------------------------
    $mission = "Make ReachX a strong employer worker platform with good economics."
    $vision  = "Always on worker pool, happy employers, and clear dormitory and capacity visibility."
    $status  = "ReachX tables for employers, workers, requests, assignments, and dormitories are live."
    $block   = "No automatic summary of workers, employers, open requests, and dorm occupancy yet."
    $improv  = "Generate daily counts and simple KPIs for ReachX and surface them in a basic dashboard."
    $eta     = "Daily ReachX summary within 21 days and a simple dashboard within 45 days."

    New-DirectorSnapshot -Director "ORION" `
        -Mission $mission -Vision $vision `
        -StatusText $status -BlockersText $block `
        -ImprovementsText $improv -EtaText $eta `
        -Meta @{ date = $todayLabel; reporter = "BoardAgent"; domain = "Talent" }

    # -------- NOVA (EduConnect) --------------------------------------
    $mission = "Build EduConnect as a sellable product platform, not a one off service."
    $vision  = "A plug and play education platform that clients can license with minimal setup."
    $status  = "EduConnect direction as a product is clear but tiers, onboarding, and demo flows are still draft."
    $block   = "No final product tiers, no automated onboarding, and no demo or sandbox flow yet."
    $improv  = "Define 2 to 3 EduConnect tiers and wire a landing to demo to proposal funnel."
    $eta     = "Draft tiers within 10 days and a demoable flow within 30 to 45 days."

    New-DirectorSnapshot -Director "NOVA" `
        -Mission $mission -Vision $vision `
        -StatusText $status -BlockersText $block `
        -ImprovementsText $improv -EtaText $eta `
        -Meta @{ date = $todayLabel; reporter = "BoardAgent"; domain = "EduConnect" }

    # -------- HELIOS (Finance) ---------------------------------------
    $mission = "Protect cash, manage risk, and support the path to the first 1M."
    $vision  = "Simple dashboards that show runway, ROI, and main risks at a glance."
    $status  = "Financial view is still manual. No automated snapshot of balances, obligations, and runway."
    $block   = "No single source of truth wired into Jarvis for money data."
    $improv  = "Choose the finance source of truth and script a weekly Helios brief."
    $eta     = "First automated weekly brief within 30 days and daily micro summary within 60 days."

    New-DirectorSnapshot -Director "HELIOS" `
        -Mission $mission -Vision $vision `
        -StatusText $status -BlockersText $block `
        -ImprovementsText $improv -EtaText $eta `
        -Meta @{ date = $todayLabel; reporter = "BoardAgent"; domain = "Finance" }

    # -------- LUNA (Brand) -------------------------------------------
    $mission = "Make every AOGRL touchpoint feel premium and consistent."
    $vision  = "A unified visual style across AOGRL, OKASINA, ReachX, and EduConnect."
    $status  = "Core brand assets exist but are scattered and not linked to campaigns or performance."
    $block   = "No central asset library and no mapping from creatives to results."
    $improv  = "Create a simple shared asset library per brand and track where key visuals are used."
    $eta     = "Structured asset library within 21 days and basic mapping within 45 to 60 days."

    New-DirectorSnapshot -Director "LUNA" `
        -Mission $mission -Vision $vision `
        -StatusText $status -BlockersText $block `
        -ImprovementsText $improv -EtaText $eta `
        -Meta @{ date = $todayLabel; reporter = "BoardAgent"; domain = "Brand" }

    Write-Log "All director snapshots submitted (ATLAS, VEGA, ORION, NOVA, HELIOS, LUNA)."
}
catch {
    Write-Log ("ERROR: {0}" -f $_.Exception.Message) "ERROR"
}
finally {
    Write-Log "=== Jarvis-BoardAgent END ==="
}
