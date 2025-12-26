<# Run-Harvis.ps1 — launches Harvis-Loop, tails logs, shows status, holds window #>

param(
  [string]$ProjectPath = "F:\AION-ZERO\a-one-marcom",
  [switch]$NoGit,
  [switch]$Hold = $true
)

$loop   = "F:\AION-ZERO\tasks\Harvis-Loop.ps1"
$logDir = "F:\AION-ZERO\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }

# Prefer pwsh if present; else Windows PowerShell
$pw = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $pw) { $pw = (Get-Command powershell -ErrorAction Stop).Source }

# Pass args to loop
$argList = @('-NoProfile','-ExecutionPolicy','Bypass','-File', $loop, '-ProjectPath', $ProjectPath)
if ($NoGit) { $argList += '-NoGit' }

# Run in same window; wait for completion
Start-Process -FilePath $pw -ArgumentList $argList -NoNewWindow -Wait

# After-run: tail latest log + show status
$latest = Get-ChildItem "$logDir\harvis_*.log" -ErrorAction SilentlyContinue |
  Sort-Object LastWriteTime -Desc | Select-Object -First 1

if ($latest) {
  "`n---- TAIL: $($latest.FullName) ----" | Write-Host
  Get-Content $latest.FullName -Tail 120
} else {
  "No harvis_*.log found in $logDir" | Write-Host
}

$statusPath = Join-Path $logDir 'harvis_status.txt'
if (Test-Path $statusPath) {
  "`nSTATUS: $(Get-Content $statusPath -Raw)" | Write-Host
}

if ($Hold) { Read-Host "`nDone. Press Enter to close..." | Out-Null }
