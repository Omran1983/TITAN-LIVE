param(
    [switch]$NoReachX
)

$ErrorActionPreference = "Stop"

# Root of the engine
$root = "F:\AION-ZERO"

Write-Host "=== Jarvis Engine Boot ==="

# 1) Load master env (Supabase keys, etc.)
$useEnv = Join-Path $root "scripts\Use-ProjectEnv.ps1"
if (Test-Path $useEnv) {
    & $useEnv
} else {
    Write-Warning "Use-ProjectEnv.ps1 not found at $useEnv"
}

# 2) Start Jarvis HQ API
$apiScript = Join-Path $root "jarvis-hq\scripts\Run-Api.ps1"
if (Test-Path $apiScript) {
    Write-Host "Starting Jarvis HQ API..."
    Start-Process powershell `
        -WorkingDirectory (Split-Path $apiScript) `
        -ArgumentList @(
            "-NoExit",
            "-ExecutionPolicy","Bypass",
            "-File",$apiScript
        )
} else {
    Write-Warning "Run-Api.ps1 not found at $apiScript"
}

# 3) Start Command Worker
$workerScript = Join-Path $root "scripts\Jarvis-CommandWorker.ps1"
if (Test-Path $workerScript) {
    Write-Host "Starting Jarvis Command Worker..."
    Start-Process powershell `
        -WorkingDirectory (Split-Path $workerScript) `
        -ArgumentList @(
            "-NoExit",
            "-ExecutionPolicy","Bypass",
            "-File",$workerScript
        )
} else {
    Write-Warning "Jarvis-CommandWorker.ps1 not found at $workerScript"
}

# 4) Optionally start ReachX UI
if (-not $NoReachX) {
    $reachxLauncher = Join-Path $root "scripts\ReachX-LaunchUI.ps1"
    if (Test-Path $reachxLauncher) {
        Write-Host "Starting ReachX UI..."
        Start-Process powershell `
            -WorkingDirectory (Split-Path $reachxLauncher) `
            -ArgumentList @(
                "-NoExit",
                "-ExecutionPolicy","Bypass",
                "-File",$reachxLauncher
            )
    } else {
        Write-Warning "ReachX-LaunchUI.ps1 not found at $reachxLauncher"
    }
}

Write-Host "=== Engine boot command finished. Check the opened PS windows. ==="
