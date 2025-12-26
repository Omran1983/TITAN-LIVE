# C:\Users\ICL  ZAMBIA\Desktop\Binance Automation\trader.ps1
# Exposes Run-TrendBot for start-trend.ps1 to call (PS5/PS7 safe)

function Invoke-PythonTrend {
  param(
    [string[]]$Symbols,
    [string]  $Interval,
    [double]  $QuotePerBuy,
    [int]     $CooldownSec,
    [switch]  $Live,
    [switch]  $Once
  )

  # Find Python (support 'python' and 'py')
  $cmd = Get-Command python -ErrorAction SilentlyContinue
  if (-not $cmd) { $cmd = Get-Command py -ErrorAction SilentlyContinue }
  if (-not $cmd) { throw "Python not found on PATH. Install Python 3.x and ensure 'python' or 'py' resolves." }
  $py = $cmd.Source

  # Detect an entry script (tweak names to match your repo if needed)
  $repo = (Get-Location).Path
  $candidates = @(
    'run_trend.py','trend_loop.py','trend.py',
    'scripts\run_trend.py','scripts\trend_loop.py'
  ) | ForEach-Object { Join-Path $repo $_ }

  $entry = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $entry) {
    $pyList = (Get-ChildItem -Path $repo -Recurse -Include *.py -ErrorAction SilentlyContinue |
               Select-Object -ExpandProperty FullName)
    $hint = ($pyList | Select-Object -First 10) -join "`n  "
    throw @"
No Python trading entry script found.
Create one of these and re-run:
  - run_trend.py
  - trend_loop.py
  - trend.py
  - scripts\run_trend.py
  - scripts\trend_loop.py

Detected .py files (first 10):
  $hint

Alternatively, edit trader.ps1 to point to your actual script path.
"@
  }

  # Build args (adapt to your Python CLI if different)
  $args = @($entry,
    '--interval', $Interval,
    '--quote-per-buy', ([string]$QuotePerBuy),
    '--cooldown-sec', ([string]$CooldownSec)
  )

  if ($Symbols -and $Symbols.Count -gt 0) { $args += @('--symbols', ($Symbols -join ',')) }
  $env:LIVE = ($(if ($Live) { 'true' } else { 'false' }))

  if ($Once) { $args += @('--once') }

  Write-Host "▶ Running: $py $($args -join ' ')" -ForegroundColor Cyan

  & $py $args
  if ($LASTEXITCODE -ne 0) { throw "Python runner exited with code $LASTEXITCODE" }
}

function Run-TrendBot {
  param(
    [string[]]$Symbols     = @('BTCUSDT','ETHUSDT','SOLUSDT','BNBUSDT'),
    [string]  $Interval    = '15m',
    [double]  $QuotePerBuy = 25,
    [int]     $CooldownSec = 10,
    [switch]  $Live,
    [switch]  $Once
  )
  Invoke-PythonTrend -Symbols $Symbols -Interval $Interval -QuotePerBuy $QuotePerBuy `
                     -CooldownSec $CooldownSec -Live:$Live -Once:$Once
}
