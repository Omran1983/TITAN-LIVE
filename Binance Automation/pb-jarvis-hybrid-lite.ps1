param(
  [string]$EnvFile         = ".env.mainnet",

  # Cadence / rotation
  [int]   $EverySeconds    = 8,     # heartbeat / poll cadence
  [int]   $ReselectMinutes = 2,     # symbol reselection cadence

  # Risk knobs (percent inputs except MinQuoteUSD)
  [double]$TPpct           = 0.6,   # take-profit %
  [double]$SLpct           = 0.5,   # stop-loss %
  [int]   $MaxConcurrent   = 3,     # concurrent runners
  [double]$MinQuoteUSD     = 10.0,  # per-trade floor (set to 5.0 for micro-clips)
  [double]$StartPct        = 5.0,   # start % of equity
  [double]$CapPct          = 10.0   # cap % of equity
)

$ErrorActionPreference = "Stop"

# ----- Project context -----
$proj = Split-Path -Parent $MyInvocation.MyCommand.Path
$py   = Join-Path $proj ".venv\Scripts\python.exe"
$logs = Join-Path $proj "logs"
if (-not (Test-Path $logs)) { New-Item -ItemType Directory -Path $logs | Out-Null }

# ===== Helper: launch child with file redirection (no ScriptBlock handlers) =====
function Start-JarvisChild {
  param(
    [Parameter(Mandatory)][string]   $sym,
    [Parameter(Mandatory)][string[]] $ChildArgs,
    [string] $proj = $proj,
    [string] $py   = $py,
    [string] $logs = $logs
  )
  $env:PYTHONUTF8       = "1"
  $env:PYTHONIOENCODING = "utf-8"

  $ts   = Get-Date -Format "yyyyMMdd_HHmmss"
  $log  = Join-Path $logs ("live_{0}_{1}.log" -f $sym, $ts)
  $elog = Join-Path $logs ("live_{0}_{1}.err" -f $sym, $ts)

  $sp = Start-Process -FilePath $py `
    -ArgumentList $ChildArgs `
    -WorkingDirectory $proj `
    -WindowStyle Hidden `
    -NoNewWindow `
    -PassThru `
    -RedirectStandardOutput $log `
    -RedirectStandardError  $elog

  Write-Host "[OPEN] $sym → quote  (pid $($sp.Id)) → $log"
  return $sp
}

# ===== Equity probe (non-fatal) =====
function Get-EquityUSDT {
  param()
  $prevEAP = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $env:ENV_FILE = $EnvFile
    $env:PYTHONUTF8 = "1"; $env:PYTHONIOENCODING = "utf-8"
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

    $out = & $py -X utf8 -m scripts.list_balances 2>&1
    $txt = $out | Out-String
    $m = [regex]::Match($txt,'(?im)^\s*USDT\s+free\s*=\s*([0-9]+(?:\.\d+)?)')
    if ($m.Success) { return [double]$m.Groups[1].Value } else { return 0.0 }
  } catch { return 0.0 } finally { $ErrorActionPreference = $prevEAP }
}

# ===== Symbol selection (basic rotation) =====
function Pick-Symbols {
  # keep it simple; rotate top memes
  $pool = @('DOGEUSDT','SHIBUSDT','PEPEUSDT','FLOKIUSDT','BONKUSDT','WIFUSDT')
  return $pool | Select-Object -First $MaxConcurrent
}

# ===== Child arg builder (avoid $args collision) =====
function Build-ChildArgs {
  param(
    [Parameter(Mandatory)][string]$Symbol
  )
  # Convert percents to decimals where the python expects fractional numbers
  $tpDec     = [string]::Format("{0:0.###}", ($TPpct  / 100.0))
  $slDec     = [string]::Format("{0:0.###}", ($SLpct  / 100.0))
  $startDec  = [string]::Format("{0:0.###}", ($StartPct / 100.0))
  $capDec    = [string]::Format("{0:0.###}", ($CapPct   / 100.0))

  # Entry point: run_live_trade_safe.py (adjust if your repo uses a different runner)
  $scriptPath = Join-Path $proj "scripts\run_live_trade_safe.py"

  $ChildArgs = @(
    $scriptPath,
    "--symbols", $Symbol,
    "--tp",       $tpDec,
    "--sl",       $slDec,
    "--min-quote",[string]$MinQuoteUSD,
    "--start-pct",$startDec,
    "--cap-pct",  $capDec,
    "--max-conc", [string]$MaxConcurrent
  )
  return $ChildArgs
}

# ===== Header =====
Write-Host "[JARVIS LITE] Booting Hybrid runner. MaxConcurrent=$MaxConcurrent  TP=$TPpct%  SL=$SLpct%  Floor=$MinQuoteUSD  Start=$StartPct%  Cap=$CapPct%"

# Environment for python children
$env:ENV_FILE = $EnvFile
$env:PYTHONUTF8 = "1"
$env:PYTHONIOENCODING = "utf-8"

# Probe equity (optional log)
$eq = Get-EquityUSDT
if ($eq -gt 0) { Write-Host "[BAL] Free USDT: $eq" }

# Pick initial symbols
$symbols = Pick-Symbols
Write-Host ("[PICK] Watching: {0}" -f (($symbols -join ', ')))

# Track running children
$procs = [ordered]@{}   # sym -> process
$lastReselect = Get-Date

# Spawn up to MaxConcurrent
foreach ($sym in $symbols) {
  if ($procs.Count -ge $MaxConcurrent) { break }
  $childArgs = Build-ChildArgs -Symbol $sym
  $sp = Start-JarvisChild -sym $sym -ChildArgs $childArgs
  $procs[$sym] = $sp
}

# ===== Supervisor loop =====
while ($true) {
  Start-Sleep -Seconds $EverySeconds

  # Kill-switch file
  if (Test-Path (Join-Path $proj "STOP.AUTO")) {
    Write-Host "[EXIT] Kill switch detected."
    foreach ($kv in $procs.GetEnumerator()) {
      try { if (-not $kv.Value.HasExited) { Stop-Process -Id $kv.Value.Id -Force -ErrorAction SilentlyContinue } } catch {}
    }
    break
  }

  # Cull exited children & log last lines
  foreach ($sym in @($procs.Keys)) {
    $p = $procs[$sym]
    if ($p.HasExited) {
      Write-Host "[CLOSE] $sym (pid $($p.Id)) ExitCode=$($p.ExitCode)"
      $procs.Remove($sym) | Out-Null
    }
  }

  # Reselect on cadence
  $now = Get-Date
  if (($now - $lastReselect).TotalMinutes -ge $ReselectMinutes) {
    $lastReselect = $now
    $newPick = Pick-Symbols

    # Start any newly picked symbols not already running, honoring MaxConcurrent
    foreach ($sym in $newPick) {
      if ($procs.Count -ge $MaxConcurrent) { break }
      if (-not $procs.Contains($sym)) {
        $childArgs = Build-ChildArgs -Symbol $sym
        $sp = Start-JarvisChild -sym $sym -ChildArgs $childArgs
        $procs[$sym] = $sp
      }
    }
  }

  # Heartbeat
  $running = ($procs.Keys -join ', ')
  Write-Host "[HB] $(Get-Date -Format HH:mm:ss) running: $running"
}
