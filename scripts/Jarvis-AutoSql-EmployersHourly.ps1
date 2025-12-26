# F:\AION-ZERO\scripts\Jarvis-AutoSql-EmployersHourly.ps1

param(
    [int]$CommandId = 109
)

$ErrorActionPreference = "Stop"

# Simple timestamp helper
function Write-Log {
    param(
        [string]$Message
    )
    $ts = (Get-Date).ToString("s")
    Write-Host "[$ts] $Message"
}

try {
    Write-Log "=== Jarvis-AutoSql-EmployersHourly starting (CommandId=$CommandId) ==="

    # Go to project root
    Set-Location "F:\AION-ZERO"

    # 1) Load env
    Write-Log "Loading environment variables..."
    & "F:\AION-ZERO\scripts\Jarvis-LoadEnv.ps1"
    Write-Log "Environment loaded."

    # 2) Run AutoSQL for the given command
    Write-Log "Running Jarvis-RunAutoSql.ps1..."
    & "F:\AION-ZERO\scripts\Jarvis-RunAutoSql.ps1" -CommandId $CommandId

    Write-Log "Jarvis-RunAutoSql.ps1 finished."

} catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    # Optional: write to a simple log file for later debugging
    $logLine = "$(Get-Date -Format s) | ERROR | $($_.Exception.Message)"
    $logFile = "F:\AION-ZERO\logs\Jarvis-AutoSql-EmployersHourly.log"

    if (-not (Test-Path "F:\AION-ZERO\logs")) {
        New-Item -ItemType Directory -Path "F:\AION-ZERO\logs" | Out-Null
    }
    Add-Content -Path $logFile -Value $logLine
}
