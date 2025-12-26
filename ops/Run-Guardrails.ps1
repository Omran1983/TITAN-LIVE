param(
  [string]$RunDir = "$(Join-Path 'F:\AION-ZERO\out' ((Get-Date).ToString('yyyyMMdd_HHmmss')))",
  [string]$ModuleChanged = ""
)

New-Item -ItemType Directory -Force -Path $RunDir | Out-Null
$sbom = Join-Path $RunDir "sbom-lite.json"
$sec  = Join-Path $RunDir "security-report.html"
$rep  = Join-Path $RunDir "report.html"
$met  = Join-Path $RunDir "metrics.json"

# Collect quick metadata (files changed via git if available)
$git = Get-Command git -ErrorAction SilentlyContinue
$changed = @()
if ($git) { $changed = (& git diff --name-only | Where-Object { $_ -ne "" }) }
if (-not $changed) { $changed = Get-ChildItem -Recurse -File | Select-Object -Expand FullName }

# Simple SBOM-lite
$files = @()
foreach ($f in $changed) {
  try {
    $hash = (Get-FileHash $f -Algorithm SHA256).Hash
    $files += [pscustomobject]@{ path=$f; sha256=$hash }
  } catch {}
}
@{ timestamp=(Get-Date); files=$files } | ConvertTo-Json -Depth 5 | Out-File -Encoding UTF8 $sbom

# Security checks (regex-based quick scan)
$bad = @()
$secretPat = '(?i)(api[_-]?key|secret|token|password)\s*[:=]\s*["''][A-Za-z0-9_\-]{16,}["'']'
$migrationPat = '(?i)(migrations?[/\\]|alembic|django_migrations)'
foreach ($f in $changed) {
  $t = (Get-Content $f -Raw -ErrorAction SilentlyContinue)
  if ($t -match $secretPat) { $bad += "Secret-like token in $f" }
  if ($f -match $migrationPat) { $bad += "Migration touched: $f" }
}

# CORE gate
$coreMap = (Get-Content 'F:\AION-ZERO\governance\CoreVsPeripheral.toml' -Raw)
$coreTouched = $false
if ($ModuleChanged -and ($coreMap -match "$ModuleChanged\s*=\s*""CORE""")) { $coreTouched = $true }

# Output security report
$html = @()
$html += "<h3>Guardrails Security Report</h3>"
if ($bad.Count -gt 0) { $html += "<p><b>Findings:</b><br/>" + ($bad -join "<br/>") + "</p>" }
else { $html += "<p>No obvious secrets/migrations found.</p>" }
if ($coreTouched) { $html += "<p><b>CORE module touched:</b> $ModuleChanged → human review REQUIRED.</p>" }
$html -join "`n" | Out-File -Encoding UTF8 $sec

# Canary metrics placeholder (hook your real canary later)
$metrics = @{ canary="pending"; p95_ms=0; error_pct=0.0 }
$metrics | ConvertTo-Json | Out-File -Encoding UTF8 $met

# HTML summary
$sum = @"
<h2>Run Summary</h2>
<ul>
<li>SBOM: $(Split-Path $sbom -Leaf)</li>
<li>Security report: $(Split-Path $sec -Leaf)</li>
<li>Metrics: $(Split-Path $met -Leaf)</li>
<li>Changed files: $($changed.Count)</li>
</ul>
"@
$sum | Out-File -Encoding UTF8 $rep

# Cost ledger line (token/runtime manual inputs later)
$ledger = 'F:\AION-ZERO\ledger\costs.csv'
if (-not (Test-Path $ledger)) { "timestamp,client,module,tokens,cost_usd,seconds" | Out-File $ledger }
"$((Get-Date).ToString('s')),internal,$ModuleChanged,0,0.00,0" | Out-File -Append $ledger

Write-Host "Guardrails bundle → $RunDir" -ForegroundColor Green
