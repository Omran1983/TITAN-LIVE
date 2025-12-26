# F:\AION-ZERO\scripts\jarvis.ps1
$ErrorActionPreference = 'Stop'

# --- Setup ----------------------------------------------------
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

if (-not (Test-Path "$scriptDir\Jarvis-LoadEnv.ps1")) {
    throw "Jarvis-LoadEnv.ps1 not found in $scriptDir"
}

. "$scriptDir\Jarvis-LoadEnv.ps1"
Write-Host "Loaded environment variables from $env:SUPABASE_URL" -ForegroundColor DarkCyan

function Show-JarvisUsage {
    Write-Host ""
    Write-Host "Jarvis CLI" -ForegroundColor Cyan
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  .\jarvis.ps1 test agents      # queue run_agent_tests + run worker once"
    Write-Host "  .\jarvis.ps1 test secops      # run SecOps tests locally"
    Write-Host "  .\jarvis.ps1 test code        # run CodeAgent tests locally"
    Write-Host "  .\jarvis.ps1 status tests     # show last agent test alerts (from DB)"
    Write-Host ""
}

function New-JarvisCommand {
    param(
        [string]$project,
        [string]$action,
        [string]$agent,
        [string]$result = ""
    )

    if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
        throw "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set in environment."
    }

    $body = @(
        @{
            project = $project
            action  = $action
            agent   = $agent
            status  = "queued"
            result  = $result
        }
    )

    $headers = @{
        apikey        = $env:SUPABASE_SERVICE_ROLE_KEY
        Authorization = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
        Accept        = "application/json"
        Prefer        = "return=representation"
    }

    $url = "$($env:SUPABASE_URL.TrimEnd('/'))/rest/v1/az_commands"

    Write-Host ">> POST $url (project=$project, action=$action, agent=$agent)" -ForegroundColor DarkGray
    $resp = Invoke-RestMethod -Method Post -Uri $url -Headers $headers `
        -ContentType "application/json" -Body ($body | ConvertTo-Json -Depth 5)

    return $resp
}

function Show-AgentTestsHistory {
    try {
        if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
            throw "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set."
        }

        $headers = @{
            apikey        = $env:SUPABASE_SERVICE_ROLE_KEY
            Authorization = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
            Accept        = "application/json"
        }

        # Uses view: az_cc_agent_tests_runs (see SQL below)
        $url = "$($env:SUPABASE_URL.TrimEnd('/'))/rest/v1/az_cc_agent_tests_runs?order=created_at.desc&limit=10"

        Write-Host ">> GET $url" -ForegroundColor DarkGray
        $rows = Invoke-RestMethod -Method Get -Uri $url -Headers $headers

        if (-not $rows) {
            Write-Host "No agent test notifications found yet." -ForegroundColor Yellow
            return
        }

        $rows |
            Select-Object id, status, created_at, result |
            Format-Table -AutoSize
    }
    catch {
        Write-Warning "Failed to fetch agent tests history: $($_.Exception.Message)"
    }
}

if ($args.Count -eq 0) {
    Show-JarvisUsage
    exit 0
}

$cmd    = $args[0].ToLower()
$target = if ($args.Count -gt 1) { $args[1].ToLower() } else { "" }

switch ($cmd) {

    'test' {
        switch ($target) {
            'agents' {
                Write-Host "=== jarvis test agents ===" -ForegroundColor Cyan

                $resp = New-JarvisCommand -project "aion_zero" -action "run_agent_tests" `
                    -agent "agent_tests" -result "Triggered from jarvis.ps1 test agents"

                $cmdId = $resp[0].id
                Write-Host "Queued run_agent_tests command id=$cmdId" -ForegroundColor Green

                Write-Host "Running Jarvis-AgentTestsWorker once..." -ForegroundColor DarkCyan
                & "$scriptDir\Jarvis-AgentTestsWorker.ps1"
                break
            }

            'secops' {
                Write-Host "=== jarvis test secops ===" -ForegroundColor Cyan
                & "$scriptDir\SecOps-RunTests.ps1"
                break
            }

            'code' {
                Write-Host "=== jarvis test code ===" -ForegroundColor Cyan
                & "$scriptDir\CodeAgent-RunTests.ps1"
                break
            }

            default {
                Write-Warning "Unknown test target '$target'"
                Show-JarvisUsage
            }
        }
    }

    'status' {
        switch ($target) {
            'tests' {
                Write-Host "=== jarvis status tests ===" -ForegroundColor Cyan
                Show-AgentTestsHistory
                break
            }
            default {
                Write-Warning "Unknown status target '$target'"
                Show-JarvisUsage
            }
        }
    }

    default {
        Write-Warning "Unknown command '$cmd'"
        Show-JarvisUsage
    }
}
