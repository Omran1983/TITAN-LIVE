# FILE: F:\AION-ZERO\scripts\Jarvis-RunProjectDeploy.ps1
# Purpose: Run deployment/start commands for a given project
# Usage:   .\Jarvis-RunProjectDeploy.ps1 -ProjectName "AOGRL-Website"

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName
)

$ErrorActionPreference = "Stop"

# Paths
$baseDir    = "F:\AION-ZERO"
$configDir  = Join-Path $baseDir "config"
$logsDir    = Join-Path $baseDir "logs"
$configPath = Join-Path $configDir "Jarvis-Projects.psd1"

if (-not (Test-Path $configPath)) {
    Write-Error "Project config not found: $configPath"
    exit 1
}

if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir | Out-Null
}

$config = Import-PowerShellDataFile -Path $configPath

if (-not $config.ContainsKey("Projects")) {
    Write-Error "Config file $configPath does not contain 'Projects' key."
    exit 1
}

$projects = $config.Projects
if (-not $projects.ContainsKey($ProjectName)) {
    Write-Error "Project '$ProjectName' not found in config. Available: $($projects.Keys -join ', ')"
    exit 1
}

$proj           = $projects[$ProjectName]
$root           = $proj.Root
$deployCommands = $proj.DeployCommands

if (-not (Test-Path $root)) {
    Write-Error "Project root does not exist: $root"
    exit 1
}

$ts      = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logsDir ("project-deploy-{0}-{1}.log" -f $ProjectName, $ts)

function Write-Log {
    param(
        [string]$Message
    )
    $line = "[{0}] {1}" -f (Get-Date -Format "s"), $Message
    $line | Tee-Object -FilePath $logFile -Append | Out-Host
}

# For Supabase telemetry
$runType    = "deploy"
$startTime  = Get-Date
$runStatus  = "success"
$runMessage = ""

$scriptsDir    = Split-Path -Parent $PSCommandPath
$postRunHelper = Join-Path $scriptsDir "Jarvis-PostProjectRun.ps1"

Write-Log "=== Jarvis Project Deploy Run ==="
Write-Log "Project   : $ProjectName"
Write-Log "Root      : $root"
Write-Log "Log file  : $logFile"

Set-Location $root

if (-not $deployCommands -or $deployCommands.Count -eq 0) {
    $runMessage = "No DeployCommands defined; nothing to do."
    Write-Log $runMessage
    Write-Log "=== Deploy run completed (no actions) for '$ProjectName' ==="

    $finished = Get-Date
    if (Test-Path $postRunHelper) {
        try {
            & $postRunHelper `
                -ProjectName $ProjectName `
                -RunType $runType `
                -Status "success" `
                -LogPath $logFile `
                -StartedAt $startTime `
                -FinishedAt $finished `
                -Message $runMessage
        } catch {
            Write-Log "WARN: Failed to push deploy run to Supabase: $($_.Exception.Message)"
        }
    }

    exit 0
}

foreach ($cmd in $deployCommands) {
    Write-Log ">> Running deploy command: $cmd"

    & cmd.exe /c $cmd
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        $runStatus  = "failed"
        $runMessage = "Command failed: $cmd (exit $exitCode)"
        Write-Log "!! $runMessage"

        $finished = Get-Date
        if (Test-Path $postRunHelper) {
            try {
                & $postRunHelper `
                    -ProjectName $ProjectName `
                    -RunType $runType `
                    -Status $runStatus `
                    -LogPath $logFile `
                    -StartedAt $startTime `
                    -FinishedAt $finished `
                    -Message $runMessage
            } catch {
                Write-Log "WARN: Failed to push deploy run to Supabase: $($_.Exception.Message)"
            }
        }

        exit $exitCode
    } else {
        Write-Log "<< Command succeeded."
    }
}

$runMessage = "Deploy run completed successfully for '$ProjectName'"
Write-Log "=== Deploy run completed successfully for '$ProjectName' ==="

$finishedOk = Get-Date
if (Test-Path $postRunHelper) {
    try {
        & $postRunHelper `
            -ProjectName $ProjectName `
            -RunType $runType `
            -Status "success" `
            -LogPath $logFile `
            -StartedAt $startTime `
            -FinishedAt $finishedOk `
            -Message $runMessage
    } catch {
        Write-Log "WARN: Failed to push deploy run to Supabase: $($_.Exception.Message)"
    }
}

exit 0
