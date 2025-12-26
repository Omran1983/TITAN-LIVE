param(
  [string]$Module,
  [string]$Args = "",
  [string]$EnvFile = ".env.mainnet",
  [string]$LogFile = ""
)
$ErrorActionPreference = "Stop"
$proj = Split-Path -Parent $MyInvocation.MyCommand.Path
$py   = Join-Path $proj ".venv\Scripts\python.exe"
$kill = Join-Path $proj "KILL.TRADING"
Set-Location $proj

if (Test-Path $kill) { Write-Host "[ABORT] Kill-switch present: $kill" -ForegroundColor Red; exit 9 }

$env:ENV_FILE = $EnvFile
$cmd = "$py -m $Module $Args"
if ($LogFile) {
  Write-Host "[RUN→LOG] $Module $Args  (ENV=$EnvFile)  → $LogFile" -ForegroundColor Cyan
  # append + tee for live view and persistence
  $pinfo = New-Object System.Diagnostics.ProcessStartInfo
  $pinfo.FileName  = "powershell.exe"
  $pinfo.Arguments = "-NoLogo -NoProfile -Command `"$py -m $Module $Args *>> `"$LogFile`"`""
  $pinfo.UseShellExecute = $false
  [System.Diagnostics.Process]::Start($pinfo) | Out-Null
} else {
  Write-Host "[RUN] $Module $Args  (ENV=$EnvFile)" -ForegroundColor Cyan
  & $py -m $Module @($Args.Split(' ') | Where-Object { $_ -ne "" })
}
