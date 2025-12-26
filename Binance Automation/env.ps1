Set-StrictMode -Version Latest

function Normalize-Path {
  param([Parameter(Mandatory)][string]$Path)
  return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}

function Load-Env {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Path, [switch]$Silent)

  $Path = Normalize-Path $Path
  if (-not (Test-Path -LiteralPath $Path)) { throw "ENV file not found: $Path" }

  $lines = Get-Content -LiteralPath $Path -ErrorAction Stop
  $dict  = [ordered]@{}

  foreach ($raw in $lines) {
    $line = $raw.Trim()
    if (-not $line -or $line -match '^\s*#') { continue }
    if ($line -match '^\s*export\s+') { $line = $line -replace '^\s*export\s+','' }
    if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') {
      $k = $matches[1]
      $v = $matches[2].Trim()
      if ($v -match '^(["''])(.*)\1$') { $v = $matches[2] }
      if ($v -notmatch '^(["'']).*\1$' -and $v -match '^(.*?)(\s+#.*)$') { $v = $matches[1].TrimEnd() }
      $dict[$k] = $v
    }
  }

  function Get-EnvVar([string]$name) {
    $p = [Environment]::GetEnvironmentVariable($name, 'Process'); if ($p) { return $p }
    $u = [Environment]::GetEnvironmentVariable($name, 'User');    if ($u) { return $u }
    return [Environment]::GetEnvironmentVariable($name, 'Machine')
  }

  function Expand-Placeholders([string]$text) {
    [regex]::Replace($text, '\$\{([A-Za-z_][A-Za-z0-9_]*)\}', {
      param($m)
      $name = $m.Groups[1].Value
      if ($dict.Contains($name) -and $dict[$name]) { $dict[$name] }
      else { $ev = Get-EnvVar $name; if ($ev) { $ev } else { '' } }
    })
  }

  foreach ($k in $dict.Keys) {
    $expanded = Expand-Placeholders $dict[$k]
    Set-Item -Path ("Env:{0}" -f $k) -Value $expanded
    if (-not $Silent) {
      $preview = if ($k -match 'KEY|SECRET|TOKEN|PASS') { '***' } else { $expanded }
      Write-Host ("[env] {0} = {1}" -f $k, $preview)
    }
  }

  if (-not $Silent) { Write-Host "âœ... ENV loaded from '$Path'" -ForegroundColor Green }
}

function Test-EnvVars {
  param([string[]]$Names = @('BINANCE_KEY','BINANCE_SECRET'))
  $ok = $true
  foreach ($n in $Names) {
    if (-not (Get-Item -ErrorAction SilentlyContinue -Path ("Env:{0}" -f $n))) { Write-Warning "Missing ENV var: $n"; $ok = $false }
  }
  return $ok
}

function Ensure-CompatEnv {
  if ($env:BINANCE_API_KEY    -and -not $env:BINANCE_KEY)    { Set-Item -Path Env:BINANCE_KEY    -Value $env:BINANCE_API_KEY }
  if ($env:BINANCE_API_SECRET -and -not $env:BINANCE_SECRET) { Set-Item -Path Env:BINANCE_SECRET -Value $env:BINANCE_API_SECRET }
  if ($env:BINANCE_BASE_URL   -and -not $env:BASE)           { Set-Item -Path Env:BASE           -Value $env:BINANCE_BASE_URL }
  if ($env:BASE -and -not $env:BASE_WS) {
    $scheme   = if ($env:BASE -like 'https*') { 'wss' } else { 'ws' }
    $root     = $env:BASE.TrimEnd('/')
    $baseHost = ($root -replace '^https?://')
    Set-Item -Path Env:BASE_WS -Value ("{0}://{1}/ws" -f $scheme, $baseHost)
  }
  if (-not $env:RECV_WINDOW) { Set-Item -Path Env:RECV_WINDOW -Value '5000' }
  if ($env:MODE -and $env:MODE -notin @('paper','live','testnet','mainnet')) { Set-Item -Path Env:MODE -Value 'paper' }
}
