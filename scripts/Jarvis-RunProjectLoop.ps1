<#
    Jarvis-RunProjectLoop.ps1
    -------------------------
    Orchestrates a single "code cycle" for one project:

      1) Run Jarvis-CodeAgent.ps1 for that project/model
      2) Run Jarvis-ApplyCodePatches.ps1 for that project
      3) Run Jarvis-TestAgent.ps1 (stub) for that project, unless -SkipTests
      4) Run Jarvis-DeployAgent.ps1 (stub) for that project, unless -SkipDeploy

    Designed to be called manually OR by Task Scheduler every N minutes.
#>

param(
    [Parameter(Mandatory = $true)][string]$Project,
    [Parameter(Mandatory = $true)][string]$Model,
    [switch]$SkipTests,
    [switch]$SkipDeploy
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Jarvis-RunProjectLoop ($Project, model=$Model) ==="
Write-Host "ScriptDir: $scriptDir"

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][ScriptBlock]$ScriptBlock
    )

    Write-Host "[RunLoop] >>> $Name ..."
    try {
        & $ScriptBlock
        Write-Host "[RunLoop] <<< $Name finished."
    }
    catch {
        Write-Error "[RunLoop] $Name FAILED: $($_.Exception.Message)"
        throw
    }
}

# 1) Run CodeAgent for this project
Invoke-Step -Name "CodeAgent" -ScriptBlock {
    & powershell -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $scriptDir "Jarvis-CodeAgent.ps1") `
        -Project $Project `
        -Model $Model
}

# 2) Apply code patches for this project
Invoke-Step -Name "ApplyCodePatches" -ScriptBlock {
    & powershell -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $scriptDir "Jarvis-ApplyCodePatches.ps1") `
        -Project $Project
}

# 3) Run tests (if not skipped)
if (-not $SkipTests) {
    if (Test-Path (Join-Path $scriptDir "Jarvis-TestAgent.ps1")) {
        Invoke-Step -Name "TestAgent" -ScriptBlock {
            & powershell -NoProfile -ExecutionPolicy Bypass `
                -File (Join-Path $scriptDir "Jarvis-TestAgent.ps1") `
                -Project $Project `
                -Environment "local"
        }
    }
    else {
        Write-Warning "[RunLoop] Jarvis-TestAgent.ps1 not found. Skipping tests."
    }
}
else {
    Write-Host "[RunLoop] Tests skipped via -SkipTests."
}

# 4) Deploy (if not skipped)
if (-not $SkipDeploy) {
    if (Test-Path (Join-Path $scriptDir "Jarvis-DeployAgent.ps1")) {
        Invoke-Step -Name "DeployAgent" -ScriptBlock {
            & powershell -NoProfile -ExecutionPolicy Bypass `
                -File (Join-Path $scriptDir "Jarvis-DeployAgent.ps1") `
                -Project $Project `
                -Environment "local"
        }
    }
    else {
        Write-Warning "[RunLoop] Jarvis-DeployAgent.ps1 not found. Skipping deploy."
    }
}
else {
    Write-Host "[RunLoop] Deploy skipped via -SkipDeploy."
}

Write-Host "=== Jarvis-RunProjectLoop ($Project) done ==="
