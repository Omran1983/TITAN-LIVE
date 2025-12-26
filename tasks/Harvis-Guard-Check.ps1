param(
  [string]$StatusFile,
  [string]$Runner,
  [string]$Wrapper,
  [string]$Project
)
try {
  if (-not (Test-Path $StatusFile)) {
    & $Runner -NoProfile -ExecutionPolicy Bypass -File $Wrapper -ProjectPath $Project -Hold:$false
    exit 0
  }
  $st = ((Get-Content $StatusFile -ErrorAction SilentlyContinue) -join "`n").Trim().ToLowerInvariant()
  if ($st -ne 'ok') {
    & $Runner -NoProfile -ExecutionPolicy Bypass -File $Wrapper -ProjectPath $Project -Hold:$false
  }
} catch { }
