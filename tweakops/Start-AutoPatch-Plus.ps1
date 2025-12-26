param([string]$ProjectRoot = "F:\AION-ZERO")

$root    = Split-Path -Parent $MyInvocation.MyCommand.Path
$queue   = Join-Path $root "queue"
$work    = Join-Path $root "work"
$patches = Join-Path $root "patches"
$engine  = Join-Path $root "engine\apply_patch.py"
New-Item -ItemType Directory -Force -Path $queue, $work, $patches | Out-Null
Write-Host "TweakOps+ watching $queue ... Ctrl+C to stop."

while ($true) {
  Get-ChildItem $queue -Filter *.json -ErrorAction SilentlyContinue | ForEach-Object {
    $owned = Join-Path $work $_.Name
    try {
      # Atomically move to work
      Move-Item -LiteralPath $_.FullName -Destination $owned -Force

      $req  = Get-Content $owned -Raw | ConvertFrom-Json
      $id   = $req.id
      $pdir = Join-Path $patches $id
      New-Item -ItemType Directory -Force -Path $pdir | Out-Null
      "INTENT: $($req.intent)" | Out-File (Join-Path $pdir "plan.md")

      $targets = @()
      if ($null -ne $req.target_files) {
        if ($req.target_files -is [System.Array]) { $targets = $req.target_files } else { $targets = @($req.target_files) }
      }
      if ($targets.Count -eq 0 -and ($req.intent -match 'change\s+cta')) {
        $targets = @('src\components\Hero.jsx','src\styles\buttons.css')
      }
      $targetsJson = ($targets | ConvertTo-Json -Compress -Depth 5)
      if ([string]::IsNullOrWhiteSpace($targetsJson)) { $targetsJson = '[]' }

      $out = & python $engine $pdir $ProjectRoot $($req.intent) $targetsJson 2>&1

      $status = "ERROR"
      if ($LASTEXITCODE -eq 0) {
        $stFile = Join-Path $pdir "status.txt"
        $status = (Test-Path $stFile) ? (Get-Content -Raw $stFile) : "UNKNOWN"
      }

      pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "Update-Report.ps1") -PatchId $id -Status $status -Notes ($out -join "`n")
      Write-Host "Processed $id → $status"
    } catch {
      Write-Host "Daemon error: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
      Remove-Item -LiteralPath $owned -Force -ErrorAction SilentlyContinue
    }
  }
  Start-Sleep -Seconds 2
}
