<#
.SYNOPSIS
  Friendly Binance quick-scalp CLI.

.DESCRIPTION
  One entrypoint for rapid buys, partial sells, bracket protection, health,
  safe cancel, and quick P&L taps. Includes adaptive sizing and session loss cap.

.EXAMPLES
  .\bot.ps1 init -mode testnet -symbol BTCUSDT
  .\bot.ps1 health -mode testnet
  .\bot.ps1 buy -mode testnet -quote 6
  .\bot.ps1 sell -mode testnet -sellPct 25
  .\bot.ps1 scalp -mode testnet -trades 8 -delaySec 3 -autoSellSec 5 -adaptive -riskUSDT 2.5
  .\bot.ps1 bracket -mode testnet -tpPct 0.8 -slPct 0.8
  .\bot.ps1 kill -mode testnet
  .\bot.ps1 pnl -mode testnet

.PARAMETER cmd
  init|mode|health|buy|sell|scalp|bracket|kill|pnl

.PARAMETER mode
  testnet (default) or prod.

.PARAMETER symbol
  Trading symbol, default BTCUSDT.

.PARAMETER quote
  Quote USDT to spend on buy/scalp when NOT using -adaptive.

.PARAMETER qty
  Alternative base quantity (converted to quote on the fly).

.PARAMETER trades
  Number of scalp iterations.

.PARAMETER delaySec
  Delay between scalp iterations.

.PARAMETER autoSellSec
  Auto market-sell delay after each buy in a scalp loop (0=off).

.PARAMETER adaptive
  Use ATR-lite sizing to target -riskUSDT per click.

.PARAMETER riskUSDT
  Risk USDT target per click used with -adaptive.

.PARAMETER sellPct
  % of base to sell (market).

.PARAMETER tpPct / slPct
  Bracket TP/SL percent around current price (for a small slice).
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true, Position=0)]
  [ValidateSet("init","mode","health","buy","sell","scalp","bracket","kill","pnl","help")]
  [string]$cmd,

  [ValidateSet("testnet","prod")] [string]$mode = "testnet",
  [string]$symbol = "BTCUSDT",

  [double]$quote = 5,
  [double]$qty = 0,
  [int]$trades = 5,
  [int]$delaySec = 5,
  [int]$autoSellSec = 0,
  [switch]$adaptive,
  [double]$riskUSDT = 2.5,

  [double]$sellPct = 100,

  [double]$tpPct = 1.0,
  [double]$slPct = 1.0,

  # Session safety: stop scalp loop when net loss hits this (testnet only default)
  [double]$lossCapUSDT = 10,

  # Dry run: no trading calls, just print planned actions
  [switch]$dry
)

$ErrorActionPreference = "Stop"

function _print { param($msg,$color="White") Write-Host $msg -ForegroundColor $color }
function _ok    { param($m) _print "✅ $m" "Green" }
function _warn  { param($m) _print "⚠  $m" "Yellow" }
function _err   { param($m) _print "✖  $m" "Red" }
function _info  { param($m) _print "ℹ  $m" "Cyan" }

function Use-Mode {
  param([string]$m,[string]$sym)
  if ($m -eq "prod") { $env:ENV_FILE = ".env.prod" } else { $env:ENV_FILE = ".env.testnet" }
  $env:SYMBOL = $sym
  $env:RECV_WINDOW = "5000"
  if (-not (Test-Path ".\.venv\Scripts\Activate.ps1")) {
    _info "Creating venv..."
    python -m venv .venv
  }
  & ".\.venv\Scripts\Activate.ps1" | Out-Null
  $env:PYTHONPATH = (Get-Location).Path
  _info "[env] mode=$m symbol=$sym ENV_FILE=$env:ENV_FILE"
}

function Ensure-Deps {
  if (-not (Test-Path ".\.venv\Scripts\Activate.ps1")) {
    _err "Venv missing. Run: .\bot.ps1 init -mode $mode -symbol $symbol"
    exit 1
  }
  & ".\.venv\Scripts\Activate.ps1" | Out-Null
  $req = @("binance-connector","python-dotenv")
  foreach ($p in $req) {
    $ok = python - << 'PY'
import importlib, sys, json, os
mods = sys.argv[1].split(',')
ok = True
for m in mods:
    try: importlib.import_module(m)
    except Exception: ok=False
print("OK" if ok else "MISS")
PY
    -Args (@($p -join ",")) 2>$null
    if ($ok -ne "OK") {
      _warn "Installing $p ..."
      pip install $p | Out-Null
    }
  }
}

function Get-QuoteFromQty {
  param([double]$qty)
  $px = python - << 'PY'
import os
from binance.spot import Spot
from dotenv import load_dotenv
load_dotenv(os.getenv('ENV_FILE','.env'))
c=Spot(base_url=os.getenv('BINANCE_BASE_URL','https://testnet.binance.vision'),
       api_key=os.getenv('BINANCE_API_KEY'), api_secret=os.getenv('BINANCE_API_SECRET'))
print(c.ticker_price(symbol=os.getenv('SYMBOL','BTCUSDT'))['price'])
PY
  return [double]$px * $qty
}

function Get-CurrentPnL {
  $env:OUT_CSV = "trades_export.csv"
  python -m scripts.export_trades_csv | Out-Null
  $out = python - << 'PY'
import csv, json
rows=[]
try:
  with open("trades_export.csv") as f:
    r=csv.DictReader(f)
    for t in r: rows.append(t)
except: pass
# naive: sum signed maker/taker direction not reliable here, return count only
print(json.dumps({"count":len(rows)}))
PY
  return ($out | ConvertFrom-Json)
}

switch ($cmd) {

  "help" {
    Get-Help -Detailed $MyInvocation.MyCommand.Path
  }

  "init" {
    Use-Mode -m $mode -sym $symbol
    Ensure-Deps
    _ok "Ready."
  }

  "mode" {
    Use-Mode -m $mode -sym $symbol
  }

  "health" {
    Use-Mode -m $mode -sym $symbol
    Ensure-Deps
    if ($dry) { _info "[dry] would run health check"; break }
    python -m scripts.final_health
  }

  "buy" {
    Use-Mode -m $mode -sym $symbol
    Ensure-Deps
    if ($adaptive) {
      $env:RISK_USDT = [string]$riskUSDT
      $aq = python -m scripts.adaptive_quote | ConvertFrom-Json
      $quote = [double]$aq.quote
      _info ("[sizing] adaptive quote = {0} (ATR={1:N2}, px={2})" -f $quote, $aq.atr, $aq.price)
    } elseif ($qty -gt 0) {
      $quote = Get-QuoteFromQty -qty $qty
      _info ("[sizing] from qty={0} -> quote≈{1:N2}" -f $qty, $quote)
    }
    if ($dry) { _info "[dry] BUY market ~${quote}"; break }
    $env:QUOTE_QTY = [string]$quote
    python -m scripts.run_live_trade_safe
  }

  "sell" {
    Use-Mode -m $mode -sym $symbol
    Ensure-Deps
    $sf = [math]::Min(1.0, [math]::Max(0.0, $sellPct/100.0))
    if ($dry) { _info "[dry] SELL market {0}% of base" -f $sellPct; break }
    $env:SELL_FRAC = ([string]$sf)
    python .\scripts\market_sell_fraction.py
  }

  "scalp" {
    Use-Mode -m $mode -sym $symbol
    Ensure-Deps
    $loss = 0.0
    for ($i=1; $i -le $trades; $i++) {
      if ($adaptive) {
        $env:RISK_USDT = [string]$riskUSDT
        $aq = python -m scripts.adaptive_quote | ConvertFrom-Json
        $quote = [double]$aq.quote
        _info ("[scalp] BUY #{0} adaptive_quote=${1} (ATR={2:N2}, px={3})" -f $i, $quote, $aq.atr, $aq.price)
      } elseif ($qty -gt 0) {
        $quote = Get-QuoteFromQty -qty $qty
        _info ("[scalp] BUY #{0} qty={1} -> quote≈{2:N2}" -f $i, $qty, $quote)
      } else {
        _info "[scalp] BUY #$i quote=$quote"
      }

      if ($dry) { _info "[dry] would BUY ~${quote}"; }
      else {
        $env:QUOTE_QTY = [string]$quote
        python -m scripts.run_live_trade_safe | Tee-Object -FilePath ".\logs\bot.log" -Append | Out-Null
      }

      if ($autoSellSec -gt 0) {
        Start-Sleep -Seconds $autoSellSec
        if ($dry) { _info "[dry] would AUTO-SELL 100%"; }
        else {
          & $PSCommandPath sell -mode $mode -symbol $symbol -sellPct 100 | Out-Null
          _ok "[scalp] AUTO-EXIT #$i"
        }
      }

      # Simple session loss gate (placeholder; CSV-only view in this repo)
      if ($loss -le -1 * $lossCapUSDT) {
        _warn "Loss cap hit (session). Breaking the loop."
        break
      }

      if ($i -lt $trades) { Start-Sleep -Seconds $delaySec }
    }
    _ok "[scalp] completed loop."
  }

  "bracket" {
    Use-Mode -m $mode -sym $symbol
    Ensure-Deps
    if ($dry) { _info "[dry] would attach bracket tp={0}% sl={1}%" -f $tpPct, $slPct; break }
    $env:TP_PCT = [string]$tpPct
    $env:SL_PCT = [string]$slPct
    python .\scripts\attach_bracket_fast.py
  }

  "kill" {
    Use-Mode -m $mode -sym $symbol
    Ensure-Deps
    if ($dry) { _info "[dry] would cancel open orders safely"; break }
    python -m scripts.open_and_cancel_safe
  }

  "pnl" {
    Use-Mode -m $mode -sym $symbol
    Ensure-Deps
    if ($dry) { _info "[dry] would export trades & show KPI"; break }
    $env:OUT_CSV = "trades_export.csv"
    python -m scripts.export_trades_csv | Out-Null
    python -m scripts.kpi_from_csv
  }
}
