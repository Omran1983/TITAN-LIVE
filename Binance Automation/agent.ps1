$ErrorActionPreference = "Stop"

# Paths
$root    = Split-Path -Parent $MyInvocation.MyCommand.Path
$journal = Join-Path $root "journal"
$log     = Join-Path $journal "agent.log"
$lock    = Join-Path $journal "agent.lock"

if (!(Test-Path $journal)) { New-Item -ItemType Directory -Force -Path $journal | Out-Null }

# -------- Single-instance via FILE LOCK (no mutex, no [ref]) --------
try {
  # Open or create lock file exclusively; will throw if another instance holds it
  $lockStream = [System.IO.File]::Open($lock, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
  # Record PID for debugging
  $bytes = [System.Text.Encoding]::UTF8.GetBytes(([string]([System.Diagnostics.Process]::GetCurrentProcess().Id)))
  $lockStream.SetLength(0); $lockStream.Write($bytes,0,$bytes.Length); $lockStream.Flush()
} catch {
  exit 0  # another instance is running; bail silently
}

try {
  try { Stop-Transcript | Out-Null } catch {}
  Start-Transcript -Path $log -Append | Out-Null
  Set-Location -LiteralPath $root
  Write-Host ("JARVIS wrapper starting: {0}" -f (Get-Date -Format s))

  # Resolve pinned entry only (prevents self recursion)
  $entryFile = Join-Path $root "entry.path.txt"
  if (!(Test-Path $entryFile)) { Write-Host "ERROR: entry.path.txt missing."; exit 2 }
  $entry = (Get-Content -LiteralPath $entryFile -Raw).Trim()
  if ([string]::IsNullOrWhiteSpace($entry)) { Write-Host "ERROR: entry.path.txt empty."; exit 3 }
  if (!(Test-Path $entry)) { Write-Host "ERROR: entry script not found: $entry"; exit 4 }

  $entryFull = [IO.Path]::GetFullPath($entry)
  $selfFull  = [IO.Path]::GetFullPath($MyInvocation.MyCommand.Path)
  if ($entryFull.Trim().ToLower() -eq $selfFull.Trim().ToLower()) {
    Write-Host "ERROR: entry points to agent.ps1 (refusing to recurse)."; exit 5
  }

  Write-Host "Entry: $entry"

  # Optional args from agent.args.txt (one line)
  $argFile = Join-Path $root "agent.args.txt"
  $argLine = (Test-Path $argFile) ? ((Get-Content -LiteralPath $argFile -Raw).Trim()) : ""
  if ([string]::IsNullOrWhiteSpace($argLine)) {
    Write-Host "Args: (none)"
    & $entry
  } else {
    Write-Host "Args: $argLine"
    $null = $null
    $tokens = [System.Management.Automation.PSParser]::Tokenize($argLine, [ref]$null)
    $argv = $tokens | Where-Object { $_.Type -eq "String" } | ForEach-Object { $_.Content }
    & $entry @argv
  }

  Write-Host ("JARVIS wrapper finished: {0}" -f (Get-Date -Format s))
}
catch {
  Write-Host "!! Wrapper exception: $($_.Exception.Message)"
  if ($_.ScriptStackTrace) { Write-Host "Stack:`n$($_.ScriptStackTrace)" }
}
finally {
  try { Stop-Transcript | Out-Null } catch {}
  if ($lockStream) { $lockStream.Dispose() }  # release file lock
}
