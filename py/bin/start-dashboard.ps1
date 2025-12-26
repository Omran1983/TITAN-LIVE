param()
$ErrorActionPreference = 'Stop'

$Root   = 'F:\AION-ZERO\py'
$AppDir = Join-Path $Root 'azdash'
$PyExe  = Join-Path $Root 'venv\Scripts\python.exe'
$Logs   = Join-Path $AppDir 'logs'
$Port   = 8787
New-Item -ItemType Directory -Force -Path $Logs | Out-Null

function Stop-PortUser {
  param([int]$Port)
  try {
    $owning = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue |
              Select-Object -ExpandProperty OwningProcess -Unique
  } catch { $owning = @() }
  foreach ($procId in $owning) {
    try { Get-Process -Id $procId -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue } catch {}
  }
}

# Free port & any uvicorn/http.server on 8787
Stop-Process -Name 'uvicorn' -Force -ErrorAction SilentlyContinue
Stop-PortUser -Port $Port

$ts   = Get-Date -Format 'yyyyMMdd_HHmmss'
$StdO = Join-Path $Logs "uvicorn_out_$ts.log"
$StdE = Join-Path $Logs "uvicorn_err_$ts.log"

$env:PYTHONPATH = $Root

# Build args and use splatting (robust; no line continuations)
$uvArgs  = @('-m','uvicorn','azdash.api:app','--host','127.0.0.1','--port',"$Port")
$params  = @{
  FilePath               = $PyExe
  NoNewWindow            = $true
  ArgumentList           = $uvArgs
  RedirectStandardOutput = $StdO
  RedirectStandardError  = $StdE
}
Start-Process @params | Out-Null

Write-Host "Dashboard starting on http://localhost:$Port/ui"

