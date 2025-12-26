$ErrorActionPreference = 'Stop'

# hard mutes
$env:JARVIS_EMAIL_DISABLE = '1'
$env:EDU_WEB_DISABLE      = '1'
$env:EDU_API_HEALTH       = 'https://educonnect-api.dubsy1983-51e.workers.dev/health'

$az     = 'F:\AION-ZERO'
$build  = 'F:\AION-ZERO\build\Build-AZ.ps1'
$logDir = Join-Path $az 'logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log    = Join-Path $logDir ('build-az-' + (Get-Date -Format 'yyyyMMdd') + '.log')

function Log([string]$msg){
  Add-Content -Path $log -Value ("[{0}] {1}" -f (Get-Date -Format 'dd/MM/yyyy HH:mm:ss'), $msg)
}

try {
  $code = try { (Invoke-WebRequest $env:EDU_API_HEALTH -UseBasicParsing -TimeoutSec 6).StatusCode } catch { 0 }
  if ($code -ne 200) { Log ("EDU not healthy ({0}) - skip" -f $code); exit 0 }

  if (-not (Test-Path $build)) { Log 'Build-AZ.ps1 missing'; exit 1 }

  Log ('AZ run: start (PID={0})' -f $PID)
  & $build *>> $log 2>&1
  $ec = $LASTEXITCODE
  if ($ec -ne $null -and $ec -ne 0) {
    Log ('AZ run: finished with exit code {0}' -f $ec)
    exit $ec
  } else {
    Log 'AZ run: end OK'
  }
}
catch {
  Log ('AZ run: error {0}' -f $_.Exception.Message)
  exit 1
}
