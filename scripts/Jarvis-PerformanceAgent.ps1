param()

$ErrorActionPreference = 'Stop'

Write-Host "=== Jarvis-PerformanceAgent ==="

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

$commandsUrl = "$baseUrl/rest/v1/az_commands?select=*&project=eq.aion_zero&agent=eq.performance&status=eq.queued&order=created_at.asc&limit=10"

Write-Host "Fetching queued performance commands ..."
$commands = Invoke-RestMethod -Method Get -Uri $commandsUrl -Headers $headers

if (-not $commands -or $commands.Count -eq 0) {
    Write-Host "No queued performance commands found. Exiting."
    return
}

foreach ($cmd in $commands) {
    $id = $cmd.id
    Write-Host "Processing performance command id=$id (action=$($cmd.action)) ..."

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
            "run_performance_checks" {
                Write-Host "Recording stub performance checks ..."

                $perfUrl = "$baseUrl/rest/v1/az_performance_checks"

                $checks = @(
                    @{
                        project   = "aion_zero"
                        target    = "commands_api"
                        metric    = "latency_ms"
                        value     = 150
                        threshold = 500
                        status    = "ok"
                        meta      = @{ source = "PerformanceAgent"; command_id = $id }
                    },
                    @{
                        project   = "aion_zero"
                        target    = "notify_worker"
                        metric    = "latency_ms"
                        value     = 300
                        threshold = 800
                        status    = "ok"
                        meta      = @{ source = "PerformanceAgent"; command_id = $id }
                    }
                ) | ConvertTo-Json -Depth 5

                Invoke-RestMethod -Method Post -Uri $perfUrl -Headers $headers -ContentType "application/json" -Body $checks | Out-Null

                $resultText = "PerformanceAgent: recorded stub performance checks for commands_api + notify_worker."
            }
            Default {
                $resultText = "PerformanceAgent: unknown action '$($cmd.action)'. No checks executed."
            }
        }
    }
    catch {
        $statusText = "error"
        $resultText = "PerformanceAgent error: $($_.Exception.Message)"
    }

    $doneBody = @{
        status      = $statusText
        finished_at = (Get-Date).ToString("o")
        result      = $resultText
    } | ConvertTo-Json -Depth 5

    Invoke-RestMethod -Method Patch -Uri $updateUrl -Headers $headers -ContentType "application/json" -Body $doneBody | Out-Null

    Write-Host "Finished performance command id=$id with status=$statusText"
}

Write-Host "=== Jarvis-PerformanceAgent finished ==="
