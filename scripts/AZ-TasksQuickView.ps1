# F:\AION-ZERO\scripts\AZ-TasksQuickView.ps1

$ErrorActionPreference = "Stop"

. "F:\AION-ZERO\scripts\Load-Supabase.ps1"

Write-Host "=== AZ Tasks Quick View ===" -ForegroundColor Cyan
Write-Host "SBURL: $SBURL"
Write-Host ""

# 1) Load projects
$projUri = "$SBURL/rest/v1/az_projects" +
           "?select=id,slug,name,status,priority,notes" +
           "&order=priority.asc,name.asc"

$projects = Invoke-RestMethod -Uri $projUri -Headers $SBHeaders -Method Get

if (-not $projects -or $projects.Count -eq 0) {
    Write-Host "No projects found in az_projects." -ForegroundColor Yellow
    Write-Host "Run AZ-SeedTasks.ps1 after creating schema to bootstrap." -ForegroundColor Yellow
    return
}

Write-Host "Projects:" -ForegroundColor Yellow
$projects |
  Select-Object id, slug, name, status, priority |
  Format-Table

# 2) Load tasks
$tasksUri = "$SBURL/rest/v1/az_tasks" +
            "?select=id,project_id,title,status,kind,owner,priority,last_run,last_result" +
            "&order=project_id.asc,priority.asc,id.asc"

$tasks = Invoke-RestMethod -Uri $tasksUri -Headers $SBHeaders -Method Get

Write-Host "`nTasks by project:" -ForegroundColor Yellow

foreach ($p in $projects) {
    Write-Host ""
    Write-Host ("--- {0} [{1}] (status={2}) ---" -f $p.name, $p.slug, $p.status) -ForegroundColor Cyan

    $ptasks = $tasks | Where-Object { $_.project_id -eq $p.id }

    if (-not $ptasks -or $ptasks.Count -eq 0) {
        Write-Host "  (no tasks yet)"
        continue
    }

    $ptasks |
      Select-Object `
        id,
        title,
        status,
        kind,
        owner,
        priority,
        @{ Name = "last_run";   Expression = { $_.last_run } } |
      Format-Table
}

# 3) Simple summary
Write-Host "`nSummary:" -ForegroundColor Yellow

$summary = $tasks | Group-Object status | Select-Object Name, Count
if ($summary) {
    $summary | Format-Table @{Name="Status";Expression={$_.Name}}, Count
} else {
    Write-Host "No tasks found."
}
