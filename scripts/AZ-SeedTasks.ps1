# F:\AION-ZERO\scripts\AZ-SeedTasks.ps1
# Seed projects + tasks for OKASINA & EduConnect

$ErrorActionPreference = "Stop"

. "F:\AION-ZERO\scripts\Load-Supabase.ps1"

Write-Host "=== AZ Seed Tasks ===" -ForegroundColor Cyan
Write-Host "SBURL: $SBURL"

# Common headers for writes
$headers = $SBHeaders.Clone()
$headers["Content-Type"] = "application/json"
$headers["Prefer"]       = "return=representation"

# --------------------------------------------------------------------
# 1) Ensure projects exist (insert if empty, otherwise reuse existing)
# --------------------------------------------------------------------
$projBaseUri = "$SBURL/rest/v1/az_projects"

$existingProjects = Invoke-RestMethod `
    -Uri ($projBaseUri + "?select=id,slug,name,status,priority&order=priority.asc") `
    -Headers $SBHeaders -Method Get

if (-not $existingProjects -or $existingProjects.Count -eq 0) {
    Write-Host "No projects found, inserting defaults..." -ForegroundColor Yellow

    $projectsBody = @(
        @{
            slug     = "okasina"
            name     = "OKASINA Trading"
            status   = "active"
            priority = 1
            notes    = "E-commerce + showroom automation"
        },
        @{
            slug     = "educonnect"
            name     = "EduConnect HQ"
            status   = "active"
            priority = 2
            notes    = "Training / enrollment platform"
        },
        @{
            slug     = "system"
            name     = "System / Infra"
            status   = "active"
            priority = 9
            notes    = "Core AZ/JARVIS infra tasks"
        }
    ) | ConvertTo-Json

    $insertedProjects = Invoke-RestMethod -Uri $projBaseUri -Headers $headers -Method Post -Body $projectsBody

    $projects = $insertedProjects
    Write-Host "`nInserted projects:" -ForegroundColor Yellow
} else {
    Write-Host "Projects already exist, reusing them..." -ForegroundColor Yellow
    $projects = $existingProjects
    Write-Host "`nExisting projects:" -ForegroundColor Yellow
}

$projects | Select-Object id, slug, name, status, priority | Format-Table

function Get-ProjectId {
    param([string]$Slug)

    $match = $projects | Where-Object { $_.slug -eq $Slug }
    if (-not $match) {
        throw "Could not find project with slug '$Slug'."
    }
    return $match.id
}

$okasinaId    = Get-ProjectId -Slug "okasina"
$educonnectId = Get-ProjectId -Slug "educonnect"
$systemId     = Get-ProjectId -Slug "system"

# --------------------------------------------------------------------
# 2) Abort if tasks already exist (avoid duplicate seeds)
# --------------------------------------------------------------------
$tasksBaseUri = "$SBURL/rest/v1/az_tasks"
$tasksCheck   = Invoke-RestMethod `
    -Uri ($tasksBaseUri + "?select=id&limit=1") `
    -Headers $SBHeaders -Method Get

if ($tasksCheck -and $tasksCheck.Count -gt 0) {
    Write-Host "`naz_tasks already has rows – aborting seed to avoid duplicates." -ForegroundColor Yellow
    $tasksCheck | Format-Table
    return
}

# --------------------------------------------------------------------
# 3) Helper: build tasks with identical keys for all rows
# --------------------------------------------------------------------
function New-SeedTask {
    param(
        [long]  $ProjectId,
        [string]$Title,
        [string]$Status      = "pending",
        [string]$Kind        = $null,
        [string]$Owner       = "az",
        [int]   $Priority    = 10,
        [object]$LastRunAt   = $null,
        [string]$LastResult  = $null
    )

    return @{
        project_id  = $ProjectId
        title       = $Title
        status      = $Status
        kind        = $Kind
        owner       = $Owner
        priority    = $Priority
        last_run = $LastRunAt
        last_result = $LastResult
    }
}

# --------------------------------------------------------------------
# 4) Build tasks (all objects share same keys)
# --------------------------------------------------------------------
$tasksArray = @(
    # OKASINA – core build
    (New-SeedTask -ProjectId $okasinaId `
                  -Title "OKASINA: Connect frontend to Supabase (products)" `
                  -Status "pending" -Kind "feature" -Owner "az" -Priority 1),

    (New-SeedTask -ProjectId $okasinaId `
                  -Title "OKASINA: Admin product CRUD (add/edit/delete)" `
                  -Status "pending" -Kind "feature" -Owner "az" -Priority 2),

    (New-SeedTask -ProjectId $okasinaId `
                  -Title "OKASINA: Cart + checkout fully wired to Supabase" `
                  -Status "pending" -Kind "feature" -Owner "az" -Priority 3),

    (New-SeedTask -ProjectId $okasinaId `
                  -Title "OKASINA: Daily social content draft generator" `
                  -Status "pending" -Kind "marketing" -Owner "mixed" -Priority 4),

    # EduConnect – prototype backbone
    (New-SeedTask -ProjectId $educonnectId `
                  -Title "EduConnect: Cloudflare Worker health + Supabase heartbeat" `
                  -Status "pending" -Kind "infra" -Owner "az" -Priority 1),

    (New-SeedTask -ProjectId $educonnectId `
                  -Title "EduConnect: Simple enrollment form → Supabase" `
                  -Status "pending" -Kind "feature" -Owner "az" -Priority 2),

    # System / Infra – what we already started
    (New-SeedTask -ProjectId $systemId `
                  -Title "System: AZ-Command bus stable (commands → done/error)" `
                  -Status "done" -Kind "infra" -Owner "az" -Priority 1 `
                  -LastResult "CommandPoller + wrapper + RLS working"),

    (New-SeedTask -ProjectId $systemId `
                  -Title "System: AZ health checks + snapshots into proxy_events" `
                  -Status "doing" -Kind "infra" -Owner "az" -Priority 2)
)

$tasksBodyJson = $tasksArray | ConvertTo-Json

# --------------------------------------------------------------------
# 5) Insert tasks
# --------------------------------------------------------------------
Write-Host "`nInserting tasks..." -ForegroundColor Yellow

$insertedTasks = Invoke-RestMethod `
    -Uri $tasksBaseUri `
    -Headers $headers `
    -Method Post `
    -Body $tasksBodyJson

Write-Host "`nInserted tasks:" -ForegroundColor Yellow
$insertedTasks |
  Select-Object id, project_id, title, status, kind, owner, priority |
  Format-Table

Write-Host "`nSeed complete." -ForegroundColor Green
