param()

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

$logDir  = Join-Path $ScriptDir "logs"
$logFile = Join-Path $logDir "CommandsApi-Task.log"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

"[$(Get-Date -Format o)] === Jarvis-CommandsApi-Task starting ===" | Out-File $logFile -Encoding UTF8

try {
    $envLoader = Join-Path $ScriptDir "Jarvis-LoadEnv.ps1"
    if (Test-Path $envLoader) {
        "[$(Get-Date -Format o)] Loading env via Jarvis-LoadEnv.ps1" | Out-File $logFile -Append
        & $envLoader *>> $logFile
    }

    $apiScript = Join-Path $ScriptDir "Jarvis-CommandsApi.ps1"
    if (-not (Test-Path $apiScript)) {
        "[$(Get-Date -Format o)] ERROR: CommandsApi script not found at $apiScript" | Out-File $logFile -Append
        exit 1
    }

    "[$(Get-Date -Format o)] Running Jarvis-CommandsApi.ps1 in-process..." | Out-File $logFile -Append

    # Run the API script in this same PowerShell (no extra powershell.exe, no -Port)
    & $apiScript *>> $logFile

    "[$(Get-Date -Format o)] Jarvis-CommandsApi.ps1 exited with code $LASTEXITCODE" | Out-File $logFile -Append
    exit $LASTEXITCODE
}
catch {
    "[$(Get-Date -Format o)] FATAL: $($_.Exception.Message)" | Out-File $logFile -Append
    exit 1
}
