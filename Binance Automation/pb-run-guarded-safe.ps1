param(
  [Parameter(Mandatory=$true)][string]$Module,
  [Parameter(Mandatory=$true)][string]$Args,
  [Parameter(Mandatory=$true)][string]$EnvFile,
  [Parameter(Mandatory=$true)][string]$LogFile
)

$ErrorActionPreference = "Stop"
$proj = Split-Path -Parent $MyInvocation.MyCommand.Path
$py   = Join-Path $proj ".venv\Scripts\python.exe"

# Ensure the log directory exists (don’t Resolve-Path a file that isn’t there yet)
$logDir = Split-Path -Parent $LogFile
if ($logDir -and -not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

$env:ENV_FILE = $EnvFile

# Build safe arg list (handles spaces)
$argList = @("-m", $Module) + ($Args -split '\s+')

# Launch and redirect. Note: Start-Process redirects overwrite by default.
# If you want to append, use the direct '& $py ... *>> $LogFile' form instead.
Start-Process -FilePath $py -ArgumentList $argList -NoNewWindow `
  -RedirectStandardOutput $LogFile -RedirectStandardError $LogFile
Write-Host "[RUN→LOG] $Module   (ENV=$EnvFile)  → $LogFile"
