<#
    Jarvis-BrainRouter.ps1
    ----------------------
    Lightweight brain router for Jarvis.

    Current supported mode:
      -Mode "mission-plan"

    Contract:
      - Takes a JSON payload via -InputJson
      - Returns a JSON mission plan WITH NO EXTRA TEXT

    You can later swap the internal "plan builder" with a real DeepSeek / LLM call
    as long as the output schema stays the same.
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("mission-plan")]
    [string]$Mode,

    [Parameter(Mandatory = $true)]
    [string]$BrainKey,

    [Parameter(Mandatory = $true)]
    [string]$InputJson
)

$ErrorActionPreference = "Stop"

try {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $rootDir   = Split-Path -Parent $scriptDir

    # Load env if helper exists (for future API calls)
    $loadEnv = Join-Path $scriptDir "Jarvis-LoadEnv.ps1"
    if (Test-Path $loadEnv) {
        & $loadEnv | Out-Null
    }

    # Parse the incoming payload
    $payload = $InputJson | ConvertFrom-Json -ErrorAction Stop

    switch ($Mode) {
        "mission-plan" {
            # Build a synthetic mission plan.
            # For now we tailor logic a bit for the "Bootstrap AOGRL-DS from OKASINA" style,
            # but keep it generic enough for other goals too.

            $missionId     = $payload.mission_id
            $project       = $payload.project
            $title         = $payload.title
            $goal          = $payload.goal
            $riskLevel     = $payload.risk_level
            $autopilotMode = $payload.autopilot_mode

            if (-not $riskLevel)     { $riskLevel     = "high" }
            if (-not $autopilotMode) { $autopilotMode = "approval_required" }

            # Basic heuristic for AOGRL-DS bootstrap vs generic
            $goalText = ($goal | Out-String).Trim().ToLower()

            $steps = @()

            if ($goalText -like "*okasina*" -and $goalText -like "*clone*") {
                # Opinionated steps for the AOGRL-DS from OKASINA mission
                $steps += @{
                    index          = 1
                    code           = "clone-template"
                    description    = "Clone OKASINA repo into AOGRL-DS folder and set up the new Git remote."
                    risk_level     = "medium"
                    autopilot_mode = $autopilotMode
                }
                $steps += @{
                    index          = 2
                    code           = "rename-project"
                    description    = "Rename project identifiers, environment names, and branding from OKASINA to AOGRL-DS."
                    risk_level     = "medium"
                    autopilot_mode = $autopilotMode
                }
                $steps += @{
                    index          = 3
                    code           = "wire-services"
                    description    = "Wire AOGRL-DS Supabase, Vercel, and GitHub credentials into the cloned project (no changes to OKASINA)."
                    risk_level     = "high"
                    autopilot_mode = $autopilotMode
                }
                $steps += @{
                    index          = 4
                    code           = "test-and-deploy"
                    description    = "Run tests, build, and deploy first AOGRL-DS version to Vercel under the new project."
                    risk_level     = "high"
                    autopilot_mode = $autopilotMode
                }
            }
            else {
                # Generic 4-step mission plan
                $steps += @{
                    index          = 1
                    code           = "analyze"
                    description    = "Analyze current repo and environment for project '$project' and validate prerequisites for mission."
                    risk_level     = "low"
                    autopilot_mode = $autopilotMode
                }
                $steps += @{
                    index          = 2
                    code           = "design"
                    description    = "Design a minimal, safe implementation plan to achieve the mission goal: $goal"
                    risk_level     = "medium"
                    autopilot_mode = $autopilotMode
                }
                $steps += @{
                    index          = 3
                    code           = "implement"
                    description    = "Implement code/config changes according to the mission plan and prepare for deployment."
                    risk_level     = "high"
                    autopilot_mode = $autopilotMode
                }
                $steps += @{
                    index          = 4
                    code           = "test-and-deploy"
                    description    = "Run tests and, if green and approved, deploy the updated project."
                    risk_level     = "high"
                    autopilot_mode = $autopilotMode
                }
            }

            $plan = @{
                version = 1
                brain   = $BrainKey
                mission = @{
                    id      = $missionId
                    project = $project
                }
                title   = $title
                goal    = $goal
                steps   = $steps
            }

            # IMPORTANT: Write ONLY JSON. No Write-Host, no extra text.
            $planJson = $plan | ConvertTo-Json -Depth 10
            $planJson
        }
        default {
            throw "Unsupported Mode '$Mode' in Jarvis-BrainRouter."
        }
    }
}
catch {
    # On error, DO NOT emit random text plus JSON.
    # We rethrow so MissionEngine can handle it and log a warning.
    throw
}
