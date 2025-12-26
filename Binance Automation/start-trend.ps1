param(
  [switch]$Prod,
  [ValidateSet("1m","3m","5m","15m","1h")][string]$Interval = "15m",
  [int]$QuotePerBuy = 25,
  [string[]]$Symbols = @("BTCUSDT","ETHUSDT","SOLUSDT","BNBUSDT"),
  [switch]$Once
)

# --- Fixed repo path to avoid $PSScriptRoot/MyInvocation issues ---
$Repo = "C:\Users\ICL  ZAMBIA\Desktop\Binance Automation"
Set-Location -Path $Repo

# --- Load environment helpers ---
. .\env.ps1
$envFile = if ($Prod) { ".\.env.mainnet" } else { ".\.env.testnet" }
Load-Env -Path $envFile
Ensure-CompatEnv

# --- Logging setup ---
$root = "F:\Jarvis"
$ts   = Get-Date -Format "yyyyMMdd_HHmmss"
$log  = Join-Path $root "logs\trend_${ts}.log"
New-Item -ItemType Directory -Force -Path $root, "$root\logs", "$root\runtime" | Out-Null

"=== TrendBot START $(Get-Date -Format s) ==="            | Tee-Object -FilePath $log -Append | Out-Null
"EnvFile    : $envFile"                                   | Tee-Object -FilePath $log -Append | Out-Null
"Interval   : $Interval"                                  | Tee-Object -FilePath $log -Append | Out-Null
"QuotePerBuy: $QuotePerBuy"                               | Tee-Object -FilePath $log -Append | Out-Null
"Symbols    : $($Symbols -join ', ')"                     | Tee-Object -FilePath $log -Append | Out-Null
"Live       : $([bool]$Prod)"                             | Tee-Object -FilePath $log -Append | Out-Null
"Log        : $log"                                       | Tee-Object -FilePath $log -Append | Out-Null

# --- Locate and load implementation of Run-TrendBot ---
if (-not (Get-Command Run-TrendBot -ErrorAction SilentlyContinue)) {
  $cand = Get-ChildItem -Path $Repo -Recurse -Filter *.ps1 -File -ErrorAction SilentlyContinue |
           Where-Object { Select-String -Path $_.FullName -Pattern 'function\s+Run-TrendBot\b' -Quiet -ErrorAction SilentlyContinue } |
           Select-Object -First 1
  if ($cand) {
    "Using implementation: $($cand.FullName)" | Tee-Object -FilePath $log -Append | Out-Null
    . $cand.FullName
  } else {
    "ERROR: Run-TrendBot implementation not found under $Repo" | Tee-Object -FilePath $log -Append | Out-Null
    throw "Run-TrendBot implementation not found under $Repo. Dot-source your bot file."
  }
}

# --- Build params and run (mirror output to log) ---
$params = @{
  Symbols     = $Symbols
  Interval    = $Interval
  QuotePerBuy = $QuotePerBuy
  CooldownSec = 10
  Live        = [bool]$Prod
}
if ($Once) { $params['Once'] = $true }

"--- EXECUTING Run-TrendBot ---" | Tee-Object -FilePath $log -Append | Out-Null
try {
  Run-TrendBot @params *>&1 | Tee-Object -FilePath $log -Append
} catch {
  "ERROR: $($_.Exception.Message)" | Tee-Object -FilePath $log -Append
  throw
} finally {
  "--- TrendBot STOP $(Get-Date -Format s) ---" | Tee-Object -FilePath $log -Append | Out-Null
  "Log saved to: $log"
}
