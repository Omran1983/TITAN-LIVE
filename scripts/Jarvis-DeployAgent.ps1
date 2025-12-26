<#
    Jarvis-DeployAgent.ps1
    ----------------------
    Stub deploy runner for Jarvis.

    Called by:
      Jarvis-RunProjectLoop.ps1

    Responsibilities (future):
      - Per-project deploy commands (Vercel, Cloudflare, etc.)
      - Only run if tests passed (enforced by RunProjectLoop/TestAgent)
      - Report status back to az_commands / az_health_snapshots

    Current behavior:
      - Logs intent only. No real deploy.
#>

param(
    [Parameter(Mandatory = $true)][string]$Project,
    [string]$Environment = "local"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Jarvis-DeployAgent ($Project, env=$Environment) ==="
Write-Host "ScriptDir: $scriptDir"

switch ($Project.ToLower()) {
    "reachx" {
        Write-Host "[DeployAgent] (stub) Would deploy ReachX here."
        Write-Host "[DeployAgent] Example (future): vercel deploy --prod for ReachX repo."
    }
    "okasina" {
        Write-Host "[DeployAgent] (stub) Would deploy OKASINA frontend here."
        Write-Host "[DeployAgent] Example (future): vercel deploy --prod or cloudflare wrangler publish."
    }
    default {
        Write-Host "[DeployAgent] (stub) No specific deploy profile for project '$Project'."
        Write-Host "[DeployAgent] Skipping real deploy (stub mode)."
    }
}

Write-Host "=== Jarvis-DeployAgent ($Project) stub complete ==="
exit 0
