# Jarvis-Metrics.ps1 — v1.3 (strict-mode safe, no ScriptBlock checks)

$__base = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }

function __GetOrInit([string]$name, [scriptblock]$factory) {
  $v = Get-Variable -Scope Script -Name $name -ErrorAction SilentlyContinue
  if (-not $v) {
    $val = & $factory
    Set-Variable -Scope Script -Name $name -Value $val -Force
    return $val
  }
  return $v.Value
}

$null = __GetOrInit 'JournalDir'   { Join-Path $__base 'journal' }
$null = __GetOrInit 'BaselinePath' { Join-Path (Get-Variable -Scope Script -Name JournalDir).Value 'baseline.json' }

New-Item -ItemType Directory -Force -Path (Get-Variable -Scope Script -Name JournalDir).Value | Out-Null

function Save-Json($obj, $path) {
  $json = $obj | ConvertTo-Json -Depth 8
  Set-Content -LiteralPath $path -Encoding UTF8 -Value $json
}

function Load-Json($path) {
  if (-not (Test-Path -LiteralPath $path)) { return [ordered]@{} }
  try { Get-Content -LiteralPath $path -Raw | ConvertFrom-Json } catch { [ordered]@{} }
}

function Get-TotalUSDTValue {
  # Minimal, self-contained spot valuation
  $missing = @()
  foreach ($req in 'BINANCE_API_KEY','BINANCE_API_SECRET') {
    if (-not [Environment]::GetEnvironmentVariable($req)) { $missing += $req }
  }
  if ($missing.Count) {
    throw "Missing env var(s): $($missing -join ', '). Set them or pass -CurrentValue to Show-Delta."
  }

  function _Sign([string]$qs) {
    $key = [Text.Encoding]::UTF8.GetBytes([Environment]::GetEnvironmentVariable('BINANCE_API_SECRET'))
    $h   = [System.Security.Cryptography.HMACSHA256]::new($key)
    $sig = $h.ComputeHash([Text.Encoding]::UTF8.GetBytes($qs))
    ($sig | ForEach-Object { $_.ToString('x2') }) -join ''
  }

  $base = if ([Environment]::GetEnvironmentVariable('BINANCE_BASE_URL')) {
            [Environment]::GetEnvironmentVariable('BINANCE_BASE_URL').TrimEnd('/')
          } else { 'https://api.binance.com' }

  $ts   = [int64]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
  $qs   = "timestamp=$ts&recvWindow=5000"
  $sig  = _Sign $qs
  $acct = Invoke-RestMethod -Method GET -Uri "$base/api/v3/account?$qs&signature=$sig" -Headers @{
            'X-MBX-APIKEY' = [Environment]::GetEnvironmentVariable('BINANCE_API_KEY')
          }

  $balances = @($acct.balances | Where-Object { [double]$_.'free' -gt 0 -or [double]$_.'locked' -gt 0 })
  if (-not $balances) { return 0.0 }

  $need = $balances.asset | Sort-Object -Unique | Where-Object { $_ -ne 'USDT' }
  $priceMap = @{}

  foreach ($a in $need) {
    $sym = "${a}USDT"
    try {
      $p = Invoke-RestMethod -Method GET -Uri "$base/api/v3/ticker/price?symbol=$sym"
      if ($p.price) { $priceMap[$a] = [double]$p.price }
    } catch { }
  }

  foreach ($st in @('USDC','FDUSD','BUSD','TUSD')) {
    if (($need -contains $st) -and -not $priceMap.ContainsKey($st)) { $priceMap[$st] = 1.0 }
  }

  [double]$total = 0
  foreach ($b in $balances) {
    $qty = [double]$b.free + [double]$b.locked
    if     ($b.asset -eq 'USDT')   { $total += $qty }
    elseif ($priceMap[$b.asset])   { $total += $qty * $priceMap[$b.asset] }
  }
  [math]::Round($total, 2)
}

function Set-BaselineIfMissing {
  param(
    [double] $Value = $(Get-TotalUSDTValue),
    [string] $Date  = (Get-Date -AsUTC).ToString('yyyy-MM-dd')
  )
  $baselinePath = (Get-Variable -Scope Script -Name BaselinePath).Value
  $db = Load-Json $baselinePath
  if ($db.PSObject.Properties.Name -notcontains $Date) {
    $db | Add-Member -NotePropertyName $Date -NotePropertyValue ([pscustomobject]@{
      ts    = (Get-Date -AsUTC).ToString('s') + 'Z'
      value = [math]::Round($Value, 2)
    })
    Save-Json $db $baselinePath
    "✅ Baseline set for $Date -> $([math]::Round($Value,2)) USDT"
  } else {
    "ℹ️ Baseline already present for $Date -> $([math]::Round([double]$db.$Date.value,2)) USDT"
  }
}

function Show-Delta {
  param(
    [string]  $Date = (Get-Date -AsUTC).ToString('yyyy-MM-dd'),
    [double]  $CurrentValue
  )
  $baselinePath = (Get-Variable -Scope Script -Name BaselinePath).Value
  $db = Load-Json $baselinePath
  if (-not $db.$Date) { throw "No baseline found for $Date. Run Set-BaselineIfMissing first." }

  [double]$baseline = [double]$db.$Date.value

  [double]$now =
    if ($PSBoundParameters.ContainsKey('CurrentValue')) {
      $CurrentValue
    } else {
      try { Get-TotalUSDTValue } catch { Write-Warning $_; 0 }
    }

  [double]$delta = $now - $baseline
  [double]$pct   = if ($baseline -eq 0) { 0 } else { ($delta / $baseline) * 100 }

  "Δ = {0} USDT ({1}%)" -f ([math]::Round($delta,2)), ([math]::Round($pct,2))
}
function Set-Baseline {
  param([double]$Value, [string]$Date = (Get-Date -AsUTC).ToString('yyyy-MM-dd'))
  $baselinePath = (Get-Variable -Scope Script -Name BaselinePath).Value
  $db = Load-Json $baselinePath
  $db.$Date = [pscustomobject]@{ ts=(Get-Date -AsUTC).ToString('s')+'Z'; value=[math]::Round($Value,2) }
  Save-Json $db $baselinePath
  "✅ Baseline overwritten for $Date -> $([math]::Round($Value,2)) USDT"
}

function Show-History {
  param([int]$Days = 7)
  $baselinePath = (Get-Variable -Scope Script -Name BaselinePath).Value
  $db = Load-Json $baselinePath
  if (-not $db.PSObject.Properties.Count) { return "No baselines yet." }
  $items = $db.PSObject.Properties | ForEach-Object {
    [pscustomobject]@{ Date=$_.Name; Value=[double]$_.Value.value; TS=$_.Value.ts }
  } | Sort-Object Date -Descending
  $items | Select-Object -First $Days | Format-Table -AutoSize
}
