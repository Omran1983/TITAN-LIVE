<#
    Jarvis-MeshHeartbeat.ps1
    ------------------------
    Lightweight heartbeat script for agents.

    - Can be called with or without parameters.
    - If AgentName is not passed, it defaults to 'Jarvis-CodeAgent'.
    - Writes a simple log line to console and to a local logfile.
    - No blocking prompts, no mandatory parameters.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$AgentName = "Jarvis-CodeAgent",

    [Parameter(Mandatory = $false)]
    [string]$Project = "AION-ZERO"
)

$ErrorActionPreference = "Stop"

# Root + log file
$rootDir = "F:\AION-ZERO"
$logDir  = Join-Path $rootDir "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$logPath = Join-Path $logDir "Jarvis-MeshHeartbeat.log"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[{0}] [{1}] {2}" -f $timestamp, $Level, $Message
    Add-Content -Path $logPath -Value $line
}

$timestamp = Get-Date -Format "o"
$consoleMsg = "MeshHeartbeat [$timestamp] AgentName='$AgentName' Project='$Project'"

Write-Host $consoleMsg
Write-Log  $consoleMsg "INFO"

# Exit cleanly so callers (CodeAgent, RunProjectLoop, etc.) don't get blocked
exit 0
