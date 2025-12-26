$ErrorActionPreference = "Stop"

# --- CONFIG ---
$EnvFilePath          = "F:\secrets\.env-main"
$ReachXProject        = "ReachX"
$UiRoot               = "F:\ReachX-AI\infra\ReachX-Workers-UI-v1"
$CheckIntervalSeconds = 300

# --- SIMPLE ENV LOADER ---
if (-not (Test-Path $EnvFilePath)) {
    Write-Host "Env file not found: $EnvFilePath" -ForegroundColor Red
    exit 1
}

$envLines = Get-Content -Path $EnvFilePath

$supLine = $envLines | Where-Object { $_ -match "^\s*SUPABASE_URL=" }         | Select-Object -Last 1
$keyLine = $envLines | Where-Object { $_ -match "^\s*SUPABASE_SERVICE_KEY=" } | Select-Object -Last 1

$SupabaseUrl = $null
$ServiceKey  = $null

if ($supLine) { $SupabaseUrl = ($supLine -replace "^\s*SUPABASE_URL=", "").Trim() }
if ($keyLine) { $ServiceKey  = ($keyLine -replace "^\s*SUPABASE_SERVICE_KEY=", "").Trim() }

if (-not $SupabaseUrl -or -not $ServiceKey) {
    Write-Host "Parsed SUPABASE_URL or SUPABASE_SERVICE_KEY is empty." -ForegroundColor Red
    Write-Host "SUPABASE_URL line:  $supLine"
    Write-Host "SERVICE_KEY line:   $keyLine"
    exit 1
}

Write-Host "Using SUPABASE_URL = $SupabaseUrl" -ForegroundColor Cyan

$Headers = @{
    apikey         = $ServiceKey
    Authorization  = "Bearer $ServiceKey"
    "Content-Type" = "application/json"
    Prefer         = "return=minimal"
}

function New-AZCommand {
    param(
        [string] $Project,
        [string] $Command,
        [object] $Args        = $null,
        [string] $TargetAgent = "Jarvis-Code-Worker",
        [string] $Status      = "queued"
    )

    if ($Args -eq $null) { $Args = @{} }

    $body = @{
        project      = $Project
        target_agent = $TargetAgent
        command      = $Command
        args         = $Args
        status       = $Status
    } | ConvertTo-Json -Depth 6

    $url = "$SupabaseUrl/rest/v1/az_commands"

    try {
        Invoke-RestMethod -Uri $url -Headers $Headers -Method Post -Body $body | Out-Null
        Write-Host "Queued: [$Project][$TargetAgent][$Command]"
    } catch {
        Write-Host "Failed to queue command: $Command" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor DarkRed
    }
}

function Test-SupaHasRows {
    param(
        [string]$TableName
    )
    try {
        $url  = "$SupabaseUrl/rest/v1/$TableName?select=id&limit=1"
        $resp = Invoke-RestMethod -Uri $url -Headers $Headers -Method Get
        return ($resp -ne $null -and $resp.Count -ge 1)
    } catch {
        return $false
    }
}

# --- 1) QUEUE AUTO-BUILD PLAN (ONE-TIME) ---

Write-Host "Queuing ReachX auto-build plan into az_commands..." -ForegroundColor Cyan

$buildTasks = @(
    @{
        Command = "reachx_build_ui"
        Args    = @{ page = "dashboard.html";   root_id = "reachx-dashboard-root" }
    },
    @{
        Command = "reachx_build_ui"
        Args    = @{ page = "employers.html";   root_id = "reachx-employers-root" }
    },
    @{
        Command = "reachx_build_ui"
        Args    = @{ page = "workers.html";     root_id = "reachx-workers-root" }
    },
    @{
        Command = "reachx_build_ui"
        Args    = @{ page = "dormitories.html"; root_id = "reachx-dorms-root" }
    },
    @{
        Command = "reachx_build_ui"
        Args    = @{ page = "requests.html";    root_id = "reachx-requests-root" }
    },
    @{
        Command = "reachx_build_ui"
        Args    = @{ page = "invoices.html";    root_id = "reachx-invoices-root" }
    },
    @{
        Command = "reachx_build_schema"
        Args    = @{ tables = @("employers","workers","dormitories","employer_requests","assignments") }
    },
    @{
        Command = "reachx_build_view"
        Args    = @{ view = "employer_invoices_view" }
    },
    @{
        Command = "reachx_wire_frontend"
        Args    = @{ pages = @("dashboard.html","employers.html","workers.html","dormitories.html","requests.html","invoices.html") }
    },
    @{
        Command = "reachx_deploy_ui"
        Args    = @{ target = "cloudflare_pages"; project = "reachx-workers-ui" }
    }
)

foreach ($t in $buildTasks) {
    New-AZCommand -Project $ReachXProject -Command $t.Command -Args $t.Args
}

Write-Host "ReachX auto-build plan queued." -ForegroundColor Green

# --- 2) SELF-HEAL LOOP ---

function SelfHeal-ReachX {
    Write-Host "[ReachX-SelfHeal] Running health checks..." -ForegroundColor Cyan

    $pages = @(
        @{ Name="dashboard.html";   Root="reachx-dashboard-root" },
        @{ Name="employers.html";   Root="reachx-employers-root" },
        @{ Name="workers.html";     Root="reachx-workers-root" },
        @{ Name="dormitories.html"; Root="reachx-dorms-root" },
        @{ Name="requests.html";    Root="reachx-requests-root" },
        @{ Name="invoices.html";    Root="reachx-invoices-root" }
    )

    foreach ($p in $pages) {
        $path = Join-Path $UiRoot $p.Name
        if (-not (Test-Path $path)) {
            New-AZCommand -Project $ReachXProject -Command "reachx_fix_ui_missing" -Args @{ page = $p.Name; root_id = $p.Root }
            continue
        }
        $content = Get-Content -Path $path -Raw
        if ($content -notlike "*$($p.Root)*") {
            New-AZCommand -Project $ReachXProject -Command "reachx_fix_ui_root" -Args @{ page = $p.Name; root_id = $p.Root }
        }
    }

    $coreTables = @("employers","workers","dormitories")
    foreach ($tbl in $coreTables) {
        if (-not (Test-SupaHasRows -TableName $tbl)) {
            New-AZCommand -Project $ReachXProject -Command "reachx_seed_table" -Args @{ table = $tbl }
        }
    }

    if (-not (Test-SupaHasRows -TableName "employer_invoices_view")) {
        New-AZCommand -Project $ReachXProject -Command "reachx_fix_view" -Args @{ view = "employer_invoices_view" }
    }

    Write-Host "[ReachX-SelfHeal] Health checks complete." -ForegroundColor Green
}

Write-Host "Starting ReachX Self-Heal loop (Ctrl+C to stop)..." -ForegroundColor Yellow

while ($true) {
    SelfHeal-ReachX
    Start-Sleep -Seconds $CheckIntervalSeconds
}
