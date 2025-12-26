param(
  [int]$IntervalSec = 600,
  [double]$PerTradeUSDT = 10,
  [int]$MaxConcurrent = 3,
  [double]$TakeProfitPct = 0.012,
  [double]$StopLossPct   = 0.018,
  [double]$MinQuoteVolume = 5e7,
  [switch]$Live
)

$ErrorActionPreference = 'Stop'
$botPath = "C:\Users\ICL  ZAMBIA\Desktop\Binance Automation\Jarvis-MemeAuto.ps1"
$logDir  = "C:\Users\ICL  ZAMBIA\Desktop\Binance Automation\journal"
$logFile = Join-Path $logDir ("loop_" + (Get-Date -Format 'yyyyMMdd') + ".log")
$stopFile = Join-Path $logDir 'STOP.txt'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

# Mutex guard (Local\ scope to avoid permissions)
$mtxName = "Local\JARVIS_MEMEAUTO_LOOP"
$createdNew = $false
$mtx = New-Object System.Threading.Mutex($false, $mtxName, [ref]$createdNew)
if (-not $createdNew) { Write-Host "Another loop instance is already running. Exiting."; exit 0 }

function Write-Log([string]$msg) {
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  $line = "[{0}] {1}" -f $ts, $msg
  $line | Tee-Object -FilePath $logFile -Append
}

Write-Log "=== JARVIS loop started (IntervalSec=$IntervalSec, Live=$($Live.IsPresent)) ==="
Write-Log "Press Ctrl+C to stop. Or create file: $stopFile"

try {
  while ($true) {
    if (Test-Path -LiteralPath $stopFile) {
      Write-Log "STOP file detected — exiting loop."
      Remove-Item -LiteralPath $stopFile -Force -ErrorAction SilentlyContinue
      break
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
      Write-Log "Running MemeAuto pass..."
      & $botPath `
        -PerTradeUSDT $PerTradeUSDT `
        -MaxConcurrent $MaxConcurrent `
        -TakeProfitPct $TakeProfitPct `
        -StopLossPct $StopLossPct `
        -MinQuoteVolume $MinQuoteVolume `
        -Live:$($Live.IsPresent) | Tee-Object -FilePath $logFile -Append
      Write-Log "Pass complete."
    } catch {
      Write-Log ("ERROR: {0}" -f $_.Exception.Message)
    } finally {
      $sw.Stop()
      $elapsed = [int][math]::Round($sw.Elapsed.TotalSeconds)
      $sleep = [math]::Max(5, $IntervalSec - $elapsed)
      Write-Log ("Sleeping {0}s (elapsed {1}s)..." -f $sleep, $elapsed)
      Start-Sleep -Seconds $sleep
    }
  }
}
finally {
  if ($mtx) {
    try {
      # Only release if we currently own it
      if ($mtx.WaitOne(0)) {
        $mtx.ReleaseMutex() | Out-Null
      }
    } catch {
      Write-Log ("Mutex release skipped: {0}" -f $_.Exception.Message)
    } finally {
      $mtx.Dispose()
    }
  }
  Write-Log "=== JARVIS loop stopped ==="
}
