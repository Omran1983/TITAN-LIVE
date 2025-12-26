param()

$ErrorActionPreference = 'Stop'

Write-Host "=== Jarvis-BusinessAgent ==="

$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$loadEnvPath = Join-Path $scriptDir "Jarvis-LoadEnv.ps1"

if (-not (Test-Path $loadEnvPath)) {
    throw "Jarvis-LoadEnv.ps1 not found at $loadEnvPath"
}

. $loadEnvPath

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    throw "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set."
}

$baseUrl = $env:SUPABASE_URL.TrimEnd('/')

$headers = @{
    apikey        = $env:SUPABASE_SERVICE_ROLE_KEY
    Authorization = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    Accept        = "application/json"
    Prefer        = "return=representation"
}

# BusinessAgent is part of the aion_zero project
$commandsUrl = "$baseUrl/rest/v1/az_commands?select=*&project=eq.aion_zero&agent=eq.business&status=eq.queued&order=created_at.asc&limit=10"

Write-Host "Fetching queued business commands ..."
$commands = Invoke-RestMethod -Method Get -Uri $commandsUrl -Headers $headers

if (-not $commands -or $commands.Count -eq 0) {
    Write-Host "No queued business commands found. Exiting."
    return
}

foreach ($cmd in $commands) {
    $id = $cmd.id
    Write-Host "Processing business command id=$id (action=$($cmd.action)) ..."

    $updateUrl = "$baseUrl/rest/v1/az_commands?id=eq.$id"

    $inProgressBody = @{
        status     = "in_progress"
        started_at = (Get-Date).ToString("o")
    } | ConvertTo-Json -Depth 5

    Invoke-RestMethod -Method Patch -Uri $updateUrl -Headers $headers -ContentType "application/json" -Body $inProgressBody | Out-Null

    $statusText = "completed"
    $resultText = ""

    try {
        switch ($cmd.action) {
            "update_business_kpis" {
                $projectKey = if ($cmd.project) { $cmd.project } else { "aion_zero" }

                # Simple period key: today (YYYY-MM-DD)
                $today     = Get-Date
                $periodKey = $today.ToString("yyyy-MM-dd")

                # Stub KPIs to light up dashboards
                $rows = @(
                    @{
                        project   = $projectKey
                        kpi_key   = "reachx_active_employers"
                        kpi_label = "ReachX - Active Employers"
                        value     = 5
                        target    = 10
                        unit      = "count"
                        period    = $periodKey
                        status    = "warning"
                        meta      = @{
                            source     = "BusinessAgent"
                            command_id = $id
                        }
                    },
                    @{
                        project   = $projectKey
                        kpi_key   = "reachx_workers_on_assignment"
                        kpi_label = "ReachX - Workers on Assignment"
                        value     = 60
                        target    = 100
                        unit      = "count"
                        period    = $periodKey
                        status    = "warning"
                        meta      = @{
                            source     = "BusinessAgent"
                            command_id = $id
                        }
                    },
                    @{
                        project   = $projectKey
                        kpi_key   = "reachx_mrr_mur"
                        kpi_label = "ReachX - Est. Monthly Recurring Revenue (MUR)"
                        value     = 150000
                        target    = 300000
                        unit      = "MUR"
                        period    = $periodKey
                        status    = "warning"
                        meta      = @{
                            source     = "BusinessAgent"
                            command_id = $id
                        }
                    }
                )

                $kpiUrl = "$baseUrl/rest/v1/az_business_kpis"

                Invoke-RestMethod `
                    -Method Post `
                    -Uri $kpiUrl `
                    -Headers $headers `
                    -ContentType "application/json" `
                    -Body ($rows | ConvertTo-Json -Depth 5) | Out-Null

                $resultText = "BusinessAgent: inserted $($rows.Count) business KPI rows for period $periodKey (project=$projectKey)."
            }
            Default {
                $resultText = "BusinessAgent: unknown action '$($cmd.action)'. No KPIs updated."
            }
        }
    }
    catch {
        $statusText = "error"
        $resultText = "BusinessAgent error: $($_.Exception.Message)"
    }

    $doneBody = @{
        status      = $statusText
        finished_at = (Get-Date).ToString("o")
        result      = $resultText
    } | ConvertTo-Json -Depth 5

    Invoke-RestMethod -Method Patch -Uri $updateUrl -Headers $headers -ContentType "application/json" -Body $doneBody | Out-Null

    Write-Host "Finished business command id=$id with status=$statusText"
}

Write-Host "=== Jarvis-BusinessAgent finished ==="
