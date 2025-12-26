param(
  [string]$AZHome = "F:\AION-ZERO",
  [int]$CycleSec = 60,
  [int]$MaxPerRun = 100
)
$ErrorActionPreference = "Stop"
$queue   = Join-Path $AZHome "bridge\file-queue"
$planned = Join-Path $AZHome "bridge\planned"
$logDir  = Join-Path $AZHome "logs"
$log     = Join-Path $logDir ("jarvis-{0}.log" -f (Get-Date -Format "yyyyMMdd"))

New-Item -ItemType Directory -Force -Path $queue,$planned,$logDir | Out-Null

function Write-Log($m){ Add-Content -Path $log -Value ("{0} | {1}" -f (Get-Date -Format "s"), $m) }

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$runId = [guid]::NewGuid().ToString("N").Substring(0,8)

# Prevent overlap if multiple triggers fire
$mutex = New-Object System.Threading.Mutex($false, "Global\JarvisWatcher-$env:USERNAME")
$hasLock = $mutex.WaitOne([TimeSpan]::FromSeconds(2))
if (-not $hasLock) { Write-Log "WATCHER | skip | locked"; return }

try {
  Write-Log ("WATCHER | start | queue={0} | run={1}" -f $queue,$runId)
  $moved = 0

  # Time budget: leave a small buffer; cap to ~55s max to avoid long hangs
  $budget = [Math]::Max(5, [Math]::Min($CycleSec - 5, 55))

  while ($true) {
    if ($sw.Elapsed.TotalSeconds -ge $budget) { break }
    if ($moved -ge $MaxPerRun) { break }

    $task = Get-ChildItem $queue -Filter "T-*.json" -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime | Select-Object -First 1
    if (-not $task) {
      if ($moved -eq 0) { Write-Log "WATCHER | idle" }
      break
    }

    Write-Log ("PICK | {0}" -f $task.Name)
    $dest = Join-Path $planned $task.Name
    try {
      Move-Item -LiteralPath $task.FullName -Destination $dest -Force
      $id = [IO.Path]::GetFileNameWithoutExtension($task.Name)
      Write-Log ("DONE | {0} -> PLANNED" -f $id)
      $moved++
    } catch {
      Write-Log ("ERROR | move | {0}" -f $_.Exception.Message)
      break
    }
  }

  Write-Log ("WATCHER | end | moved={0} | durMs={1}" -f $moved, [int]$sw.ElapsedMilliseconds)
}
finally {
  $mutex.ReleaseMutex() | Out-Null
  $mutex.Dispose()
  $sw.Stop()
}
