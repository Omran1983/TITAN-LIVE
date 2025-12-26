param(
  [string]$ProjectPath = "F:\AION-ZERO\a-one-marcom",
  [string]$LogDir      = "F:\AION-ZERO\logs",
  [string]$Branch      = "main",
  [int]   $GitRetries  = 3,
  [switch]$NoGit,
  [switch]$Quiet
)
if ($PSVersionTable.PSVersion.Major -ge 7) { $global:PSNativeCommandUseErrorActionPreference = $false }
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Force -Path $LogDir | Out-Null }
$Log = Join-Path $LogDir ("harvis_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))
$StatusPath     = Join-Path $LogDir 'harvis_status.txt'
$KillSwitchPath = Join-Path $LogDir 'harvis_killswitch.json'

function ts { (Get-Date).ToString('o') }
function Write-Log { param([string]$Message,[switch]$Error)
  $line = "$(ts) | $Message"
  if ($Error) { $line | Tee-Object -FilePath $Log -Append | Write-Error }
  else { $line | Tee-Object -FilePath $Log -Append | Out-Host }
}
function Register-FailureAndMaybeTripKillSwitch {
  param([string]$Why = "unknown")
  try { $epochNow = [int][DateTimeOffset]::Now.ToUnixTimeSeconds() } catch { $epochNow = [int][double]::Parse((Get-Date -UFormat %s)) }
  $windowS=600; $limit=3
  $arr = $null
  if (Test-Path $KillSwitchPath) { try { $arr = Get-Content $KillSwitchPath -Raw | ConvertFrom-Json } catch { $arr = $null } }
  if ($null -eq $arr) { $arr = @() } elseif ($arr -isnot [System.Array]) { $arr = @($arr) }
  $arr += [pscustomobject]@{ t=$epochNow; why=$Why }
  $cut = $epochNow - $windowS
  $arr = $arr | Where-Object { $_ -ne $null -and $_.t -gt $cut }
  ($arr | ConvertTo-Json -Depth 3) | Set-Content -Path $KillSwitchPath -Encoding ASCII
  if ($arr.Count -ge $limit) { Set-Content -Path $StatusPath -Value 'degraded-offline'; Write-Log "Kill-switch tripped (>= 3 failures in 10m). Exiting." -Error; exit 2 }
}
function Test-Online { try { Test-NetConnection github.com -Port 443 -InformationLevel Quiet } catch { $false } }
function Invoke-Step { param([Parameter(Mandatory)][string]$Label,[Parameter(Mandatory)][string]$Exe,[string[]]$Args=@())
  Write-Log "$Label"; & $Exe @Args 2>&1 | Tee-Object -FilePath $Log -Append; if ($LASTEXITCODE -ne 0) { throw "$Label failed (exit=$LASTEXITCODE)" }
}
function Read-PackageJson { param([string]$Dir)
  $pj = Join-Path $Dir 'package.json'; if (-not (Test-Path $pj)) { return $null }
  try { Get-Content $pj -Raw | ConvertFrom-Json } catch { $null }
}
function Detect-BuildStrategy { param([string]$Dir)
  $pkg = Read-PackageJson -Dir $Dir
  if ($pkg -ne $null) {
    if ($pkg.scripts -and $pkg.scripts.PSObject.Properties.Name -contains 'build') { return @{ kind='npm-script'; cmd=@('npm','run','build'); why='scripts.build' } }
    $names=@(); if ($pkg.devDependencies) { $names+=$pkg.devDependencies.PSObject.Properties.Name }; if ($pkg.dependencies) { $names+=$pkg.dependencies.PSObject.Properties.Name }
    if (($names -contains 'vite') -or (Test-Path (Join-Path $Dir 'vite.config.ts')) -or (Test-Path (Join-Path $Dir 'vite.config.js'))) { return @{ kind='vite'; cmd=@('npx','vite','build'); why='vite detected' } }
    if (($names -contains 'next') -or (Test-Path (Join-Path $Dir 'next.config.js')) -or (Test-Path (Join-Path $Dir 'next.config.mjs'))) { return @{ kind='next'; cmd=@('npx','next','build'); why='next detected' } }
  }
  $null
}
function Has-Package { param([string]$Dir) Test-Path (Join-Path $Dir 'package.json') }
function Find-Project { param([string]$Hint)
  if ($Hint -and (Test-Path $Hint) -and (Has-Package -Dir $Hint)) { return (Resolve-Path $Hint).Path }
  if (Has-Package -Dir (Get-Location).Path) { return (Get-Location).Path }
  $roots = @(); if ($Hint -and (Test-Path $Hint)) { $roots += (Resolve-Path $Hint).Path }; $roots += (Get-Location).Path; $roots = $roots | Select-Object -Unique
  $c=@()
  foreach ($r in $roots) {
    Get-ChildItem -Path $r -Directory -Recurse -Depth 4 -ErrorAction SilentlyContinue |
      Where-Object { Test-Path (Join-Path $_.FullName 'package.json') } |
      ForEach-Object { $c += $_.FullName }
  }
  $pref = $c | Where-Object { $_ -match 'a-one-marcom' } | Select-Object -First 1
  if ($pref) { return $pref }
  $c | Select-Object -First 1
}

$Pushed=$false
try {
  $work = Find-Project -Hint $ProjectPath
  if ($work) { Push-Location $work; $Pushed=$true; Write-Log "WorkingDir -> $work" } else { Write-Log "Staying in $(Get-Location) (no project found)"; throw "No JS project (package.json) found." }
  $projName = (Split-Path (Get-Location) -Leaf); $Tag = "HARVIS | $($projName.ToUpper())"
  Set-Content -Path $StatusPath -Value 'starting'

  $insideRepo=$false; try { & git rev-parse --is-inside-work-tree 2>$null | Out-Null; $insideRepo = ($LASTEXITCODE -eq 0) } catch { $insideRepo=$false }
  $hasOrigin=$false; if ($insideRepo) { & git remote get-url origin 2>$null | Out-Null; $hasOrigin = ($LASTEXITCODE -eq 0) }
  if     ($NoGit)            { Write-Log "$($Tag): -NoGit -> skipping git pull" }
  elseif (-not $insideRepo)  { Write-Log "$($Tag): Not a git repo -> skipping git pull" }
  elseif (-not $hasOrigin)   { Write-Log "$($Tag): No 'origin' remote -> skipping git pull" }
  elseif (-not (Test-Online)){ Write-Log "$($Tag): Offline -> skipping git pull" }
  else {
    $attempt=0; $code=0
    while ($attempt -lt [math]::Max(1,$GitRetries)) {
      & git fetch origin $Branch 2>&1 | Tee-Object -FilePath $Log -Append
      & git pull --rebase origin $Branch 2>&1 | Tee-Object -FilePath $Log -Append
      $code=$LASTEXITCODE; if ($code -eq 0) { break }
      $backoff = [int](5 * [math]::Pow(2,$attempt)); Write-Log "$($Tag): git pull failed (exit=$code). Retrying in ${backoff}s..."; Start-Sleep -Seconds $backoff; $attempt++
    }
    if ($code -ne 0) { throw "$($Tag): git pull failed after $attempt attempts (exit=$code)" }
  }

  $hasLock = (Test-Path 'package-lock.json') -or (Test-Path 'npm-shrinkwrap.json')
  if ($hasLock) { Write-Log "$($Tag): npm ci";      Invoke-Step -Label "$($Tag): npm ci"      -Exe 'npm' -Args @('ci') }
  else          { Write-Log "$($Tag): npm install"; Invoke-Step -Label "$($Tag): npm install" -Exe 'npm' -Args @('install') }

  $strategy = Detect-BuildStrategy -Dir (Get-Location).Path
  if ($null -eq $strategy) { throw "$($Tag): No build strategy (no scripts.build, no vite/next config)" }
  Write-Log "$($Tag): build via $($strategy.kind) ($($strategy.why))"
  Invoke-Step -Label "$($Tag): build" -Exe $strategy.cmd[0] -Args $strategy.cmd[1..($strategy.cmd.Count-1)]

  Set-Content -Path $StatusPath -Value 'ok'
  if (-not $Quiet) { Write-Log "$($Tag): SUCCESS" }
}
catch {
  $msg = $_.Exception.Message; Write-Log "ERROR | $msg" -Error
  Register-FailureAndMaybeTripKillSwitch -Why $msg
  Set-Content -Path $StatusPath -Value 'error'; exit 1
}
finally { if ($Pushed) { Pop-Location } }
