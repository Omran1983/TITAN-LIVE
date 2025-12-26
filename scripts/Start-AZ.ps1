param(
  [string]$ConfigPath = "$env:AZ_HOME\configs\preflight.json"
)
# Normalize working dir to project root
$here = Split-Path -Parent $PSCommandPath
Set-Location $here\..  # project root

if (-not (Test-Path $ConfigPath)) { Write-Error "Config not found: $ConfigPath"; exit 1 }
$cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json

Write-Host "AION-ZERO (OPEN-ACCESS)"
Write-Host "Caps: $($cfg.caps.max_steps) steps / $($cfg.caps.timeout_s)s"
Write-Host "Model: $($cfg.models.primary) via $($cfg.models.runtime) | Fallback: $($cfg.models.fallback)"
Write-Host "Bridge: $($cfg.bridges.dispatch) | Supabase Enabled: $($cfg.bridges.supabase.enabled)"
Write-Host "Telemetry: JSONL=$($cfg.telemetry.jsonl) Screenshots=$($cfg.telemetry.screenshots) Trace=$($cfg.telemetry.har_trace)"
Write-Host "Flows: $($cfg.flows.acceptance -join ', ')"
