# Daemon that applies real patches using the engine
param(
  [string]$ProjectRoot = "F:\AION-ZERO"  # adjust if needed
)
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$queue = Join-Path $root "queue"
$patches = Join-Path $root "patches"
$engine = Join-Path $root "engine\apply_patch.py"
New-Item -ItemType Directory -Force -Path $queue, $patches | Out-Null

Write-Host "TweakOps+ watching $queue ... Ctrl+C to stop."
while ($true) {
  Get-ChildItem $queue -Filter *.json | ForEach-Object {
    $req = Get-Content $_.FullName -Raw | ConvertFrom-Json
    $id = $req.id
    $pdir = Join-Path $patches $id
    New-Item -ItemType Directory -Force -Path $pdir | Out-Null
    "INTENT: $($req.intent)" | Out-File (Join-Path $pdir "plan.md")
    # Call Python engine
    $targetsJson = ($req.target_files | ConvertTo-Json -Compress)
    $py = "python"
    $args = @("$engine", "$pdir", "$ProjectRoot", "$($req.intent)", "$targetsJson")
    $out = & $py $args 2>&1
    $status = "SIMULATED"
    if ($LASTEXITCODE -eq 0) {
      if (Test-Path (Join-Path $pdir "status.txt")) {
        $status = Get-Content (Join-Path $pdir "status.txt") -Raw
      } else {
        $status = "UNKNOWN"
      }
    } else {
      $status = "ERROR"
    }
    # Update report
    pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "Update-Report.ps1") -PatchId $id -Status $status -Notes ($out -join "`n")
    Remove-Item $_.FullName -Force
    Write-Host "Processed $id → $status"
  }
  Start-Sleep -Seconds 3
}
