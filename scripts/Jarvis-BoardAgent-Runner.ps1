$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$root       = Split-Path -Parent $scriptRoot
$logDir     = Join-Path $root "logs"
$null = New-Item -ItemType Directory -Path $logDir -ErrorAction SilentlyContinue
$logPath    = Join-Path $logDir "BoardAgent-Runner.log"

function Write-Log {
    param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts [RUNNER] $Message" | Tee-Object -FilePath $logPath -Append | Out-Host
}

Write-Log "Invoking Jarvis-BoardAgent.ps1..."
try {
    & (Join-Path $scriptRoot "Jarvis-BoardAgent.ps1")
    Write-Log "Jarvis-BoardAgent.ps1 completed."
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
}
