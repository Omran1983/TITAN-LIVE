param([Parameter(Mandatory=$true)][string]$Path)

if (-not (Test-Path -LiteralPath $Path)) {
  throw "Env file not found: $Path"
}

# Read whole file, split lines, ignore comments/blank, parse KEY=VALUE (first '=' only)
$raw = Get-Content -LiteralPath $Path -Raw
$lines = $raw -split "`r?`n"
foreach ($l in $lines) {
  $t = $l.Trim()
  if (-not $t) { continue }
  if ($t.StartsWith('#')) { continue }
  $i = $t.IndexOf('=')
  if ($i -lt 1) { continue }
  $k = $t.Substring(0,$i).Trim()
  $v = $t.Substring($i+1).Trim()

  # Strip surrounding quotes if present
  if (($v.StartsWith('"') -and $v.EndsWith('"')) -or ($v.StartsWith("'") -and $v.EndsWith("'"))) {
    $v = $v.Substring(1, $v.Length-2)
  }

  Set-Item -Path ("Env:" + $k) -Value $v | Out-Null
}

# Common aliases → canonical names
if (-not $Env:BINANCE_API_KEY    -and $Env:BINANCE_KEY)    { $Env:BINANCE_API_KEY    = $Env:BINANCE_KEY }
if (-not $Env:BINANCE_API_SECRET -and $Env:BINANCE_SECRET) { $Env:BINANCE_API_SECRET = $Env:BINANCE_SECRET }
if (-not $Env:BINANCE_BASE_URL   -and $Env:BASE)           { $Env:BINANCE_BASE_URL   = $Env:BASE }

# Health banner (masked)
"Loaded .env from: $Path"
"KEY len=$($Env:BINANCE_API_KEY.Length)"
"SEC len=$($Env:BINANCE_API_SECRET.Length)"
"BASE=$($Env:BINANCE_BASE_URL)"
