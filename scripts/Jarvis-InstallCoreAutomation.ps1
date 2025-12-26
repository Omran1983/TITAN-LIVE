$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=== Jarvis - Install Core Automation (Option C) ===" -ForegroundColor Cyan
Write-Host ""

$base = "F:\AION-ZERO\scripts"

# Core always-on agents
$agents = @(
    @{
        Name   = "Jarvis-CodeAgent-Loop"
        Script = "$base\Jarvis-CodeAgent-Loop.ps1"
        Desc   = "Code / UI patch worker"
    },
    @{
        Name   = "Jarvis-AutoSql-Loop"
        Script = "$base\Jarvis-RunAutoSql.ps1"
        Desc   = "AutoSQL worker"
    },
    @{
        Name   = "Jarvis-NotifyWorker"
        Script = "$base\Jarvis-NotifyWorker.ps1"
        Desc   = "Telegram / notification worker"
    },
    @{
        Name   = "Jarvis-ReflexWorker"
        Script = "$base\Jarvis-ReflexWorker.ps1"
        Desc   = "Reflex rules engine"
    },
    @{
        Name   = "Jarvis-Watcher"
        Script = "$base\Jarvis-Watcher.ps1"
        Desc   = "Queue / system watcher"
    },
    @{
        Name   = "Jarvis-AutoHealAgent"
        Script = "$base\Jarvis-AutoHealAgent.ps1"
        Desc   = "Auto-heal supervisor"
    }
)

# Use Windows PowerShell for scheduled tasks
$psExe = "powershell.exe"

foreach ($agent in $agents) {
    $name   = $agent.Name
    $script = $agent.Script
    $desc   = $agent.Desc

    if (-not (Test-Path $script)) {
        Write-Warning "Skipping $name ($desc) - script not found at $script"
    }
    else {
        Write-Host "Installing scheduled task for $name ..." -ForegroundColor Yellow

        $taskCmd = "$psExe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`""

        schtasks /Create `
            /TN $name `
            /TR $taskCmd `
            /SC ONSTART `
            /RL HIGHEST `
            /F | Out-Null

        Write-Host " -> Task $name registered." -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "All core automation tasks have been processed." -ForegroundColor Cyan
Write-Host "They will start automatically on next reboot (for scripts that exist)." -ForegroundColor Cyan
Write-Host "You can also start them immediately with Jarvis-StartCoreAgents.ps1" -ForegroundColor DarkGray
