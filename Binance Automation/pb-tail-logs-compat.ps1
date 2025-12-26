param(
  [string]$Glob = ".\logs\live_*.log",
  [int]$PollMs = 800
)

$ErrorActionPreference = "SilentlyContinue"
$tracked = @{}   # path -> last read byte offset

function Start-Tail([string]$p) {
  if ($tracked.ContainsKey($p)) { return }
  if (Test-Path $p) {
    $len = (Get-Item $p).Length
  } else {
    $len = 0
  }
  $tracked[$p] = [long]$len
  Write-Host "`n--- Tailing $(Split-Path $p -Leaf) ---`n" -ForegroundColor Cyan
}

# seed existing files
Get-ChildItem -Path $Glob -ErrorAction SilentlyContinue | ForEach-Object { Start-Tail $_.FullName }

while ($true) {
  # discover new files
  Get-ChildItem -Path $Glob -ErrorAction SilentlyContinue | ForEach-Object { Start-Tail $_.FullName }

  foreach ($k in @($tracked.Keys)) {
    if (-not (Test-Path $k)) { continue }

    $fi = Get-Item $k
    $lenNow = [long]$fi.Length
    $pos    = [long]$tracked[$k]

    if ($lenNow -gt $pos) {
      $fs = [System.IO.File]::Open($k, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
      try {
        [void]$fs.Seek($pos, [System.IO.SeekOrigin]::Begin)
        $sr = New-Object System.IO.StreamReader($fs)
        $chunk = $sr.ReadToEnd()
        $sr.Close()
        if ($chunk) {
          $lines = $chunk -split "`r?`n"
          foreach ($line in $lines) {
            if ($line -ne "") { Write-Output $line }
          }
        }
        $tracked[$k] = $lenNow
      } finally {
        $fs.Close()
      }
    }
  }

  Start-Sleep -Milliseconds $PollMs
}
