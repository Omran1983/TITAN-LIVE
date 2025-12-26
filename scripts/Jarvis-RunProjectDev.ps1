# FILE: F:\AION-ZERO\scripts\Jarvis-RunProjectDev.ps1
# Purpose: Run development/build checks for a given project
# Usage:   .\Jarvis-RunProjectDev.ps1 -ProjectName "ReachX-AI"

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

$proj        = $projects[$ProjectName]
$root        = $proj.Root
$devCommands = $proj.DevCommands

if (-not (Test-Path $root)) {
    Write-Error "Project root does not exist: $root"
    exit 1
}

$ts      = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logsDir ("project-dev-{0}-{1}.log" -f $ProjectName, $ts)

function Write-Log {
    param(
        [string]$Message
    )
    $line = "[{0}] {1}" -f (Get-Date -Format "s"), $Message
    $line | Tee-Object -FilePath $logFile -Append | Out-Host
}

# For Supabase telemetry
$runType    = "dev"
$startTime  = Get-Date
$runStatus  = "success"
$runMessage = ""

# Path to helper
$scriptsDir     = Split-Path -Parent $PSCommandPath
$postRunHelper  = Join-Path $scriptsDir "Jarvis-PostProjectRun.ps1"

# Remember original location so we can restore it
$originalLocation = Get-Location

Write-Log "=== Jarvis Project Dev Run ==="
Write-Log "Project   : $ProjectName"
Write-Log "Root      : $root"
Write-Log "Log file  : $logFile"

Set-Location $root

if (-not $devCommands -or $devCommands.Count -eq 0) {
    Write-Log "No DevCommands defined for '$ProjectName'. Nothing to do."

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
                -Message "No DevCommands defined; nothing to do."
        } catch {
            Write-Log "WARN: Failed to push dev run to Supabase: $($_.Exception.Message)"
        }
    }

    # Restore original location before exit
    Set-Location $originalLocation
    Write-Log "=== Dev run completed (no actions) for '$ProjectName' ==="
    exit 0
}

foreach ($cmd in $devCommands) {
    # Special handling: skip missing requirements files
    $trimmed = $cmd.Trim()
    if ($trimmed -match "pip\s+install\s+-r\s+(.+\.txt)") {
        $reqPath = $Matches[1].Trim("`"'")
        if (-not (Test-Path $reqPath)) {
            Write-Log ">> Skipping dev command (requirements file not found): $cmd"
            continue
        }
    }

    Write-Log ">> Running dev command: $cmd"

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
                Write-Log "WARN: Failed to push dev run to Supabase: $($_.Exception.Message)"
            }
        }

        # Restore original location before exit
        Set-Location $originalLocation
        exit $exitCode
    } else {
        Write-Log "<< Command succeeded."
    }
}

$runMessage = "Dev run completed successfully for '$ProjectName'"
Write-Log "=== Dev run completed successfully for '$ProjectName' ==="

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
        Write-Log "WARN: Failed to push dev run to Supabase: $($_.Exception.Message)"
    }
}

# Restore original location before final exit
Set-Location $originalLocation
exit 0
