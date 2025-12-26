<#
    Jarvis-TestAgent.ps1
    --------------------
    Stub test runner for Jarvis.

    Called by:
      Jarvis-RunProjectLoop.ps1

    Responsibilities (future):
      - Per-project test commands (unit tests, lint, build checks)
      - Report success/failure back to az_commands / az_health_snapshots

    Current behavior:
      - Logs intent
      - Per-project switch is stubbed (no real tests)
#>

param(
    [Parameter(Mandatory = $true)][string]$Project,
    [string]$Environment = "local"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Jarvis-TestAgent ($Project, env=$Environment) ==="
Write-Host "ScriptDir: $scriptDir"

# In future we can load a config file (e.g. aion.config.json) to decide commands.
# For now, just stub per-project logic.

switch ($Project.ToLower()) {
    "reachx" {
        Write-Host "[TestAgent] (stub) Would run ReachX tests here."
        Write-Host "[TestAgent] Example (future): npm test or pytest in ReachX repo."
    }
    "okasina" {
        Write-Host "[TestAgent] (stub) Would run OKASINA frontend tests here."
        Write-Host "[TestAgent] Example (future): npm run test or npm run lint."
    }
    default {
        Write-Host "[TestAgent] (stub) No specific test profile for project '$Project'."
        Write-Host "[TestAgent] Skipping real tests (stub mode)."
    }
}

Write-Host "=== Jarvis-TestAgent ($Project) stub complete ==="
exit 0
