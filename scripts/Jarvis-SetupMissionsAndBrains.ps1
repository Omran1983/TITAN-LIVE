$ErrorActionPreference = "Stop"

Write-Host "=== Jarvis-SetupMissionsAndBrains ==="

# Resolve directories
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir   = Split-Path $scriptDir -Parent

$configDir = Join-Path $rootDir "config"
if (!(Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir | Out-Null
    Write-Host "Created config directory: $configDir"
}

# 1) brains.config.json
$brainsConfigPath = Join-Path $configDir "brains.config.json"

$brainsJson = @'
{
  "default_brain": "llama3-fast",
  "brains": [
    {
      "id": "llama3-fast",
      "label": "LLaMA 3 – Fast General",
      "model": "llama3",
      "endpoint": "http://127.0.0.1:11434/api/chat",
      "temperature": 0.4,
      "max_tokens": 2048,
      "roles": ["routing", "summaries", "docs", "ui-copy"],
      "risk_levels": ["low", "medium"]
    },
    {
      "id": "deepseek-reasoner",
      "label": "DeepSeek – Deep Reasoning",
      "model": "deepseek-r1",
      "endpoint": "http://127.0.0.1:11434/api/chat",
      "temperature": 0.3,
      "max_tokens": 4096,
      "roles": ["architecture", "multi-step-plans", "root-cause-analysis"],
      "risk_levels": ["medium", "high", "critical"]
    },
    {
      "id": "qwen-coder",
      "label": "Qwen – Code Specialist",
      "model": "qwen2.5-coder",
      "endpoint": "http://127.0.0.1:11434/api/chat",
      "temperature": 0.2,
      "max_tokens": 4096,
      "roles": ["code-edits", "refactor", "tests", "migrations"],
      "risk_levels": ["high", "critical"]
    }
  ]
}
'@

Set-Content -Path $brainsConfigPath -Value $brainsJson -Encoding UTF8
Write-Host "Wrote brains config: $brainsConfigPath"

# 2) Jarvis-BrainRouter.ps1
$brainRouterPath = Join-Path $scriptDir "Jarvis-BrainRouter.ps1"

$brainRouterCode = @'
param(
    [Parameter(Mandatory = $true)][string]$BrainId,
    [Parameter(Mandatory = $true)][string]$SystemPrompt,
    [Parameter(Mandatory = $true)][string]$UserPrompt
)

$ErrorActionPreference = "Stop"

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir    = Split-Path $scriptDir -Parent
$configPath = Join-Path $rootDir "config\\brains.config.json"

if (!(Test-Path $configPath)) {
    throw "Brains config not found at $configPath"
}

$brainsConfig = Get-Content $configPath -Raw | ConvertFrom-Json

$brain = $brainsConfig.brains | Where-Object { $_.id -eq $BrainId }

if (-not $brain) {
    if ($brainsConfig.default_brain) {
        $brain = $brainsConfig.brains | Where-Object { $_.id -eq $brainsConfig.default_brain }
    }
    if (-not $brain) {
        throw "Brain '$BrainId' not found and no valid default brain configured."
    }
}

$body = @{
    model   = $brain.model
    options = @{
        temperature = $brain.temperature
    }
    messages = @(
        @{
            role    = "system"
            content = $SystemPrompt
        },
        @{
            role    = "user"
            content = $UserPrompt
        }
    )
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod -Method Post -Uri $brain.endpoint -ContentType "application/json" -Body $body

if ($response.message -and $response.message.content) {
    $response.message.content
}
elseif ($response.choices -and $response.choices[0].message.content) {
    $response.choices[0].message.content
}
else {
    $response | ConvertTo-Json -Depth 10
}
'@

Set-Content -Path $brainRouterPath -Value $brainRouterCode -Encoding UTF8
Write-Host "Wrote brain router: $brainRouterPath"

# 3) Jarvis-MissionEngine.ps1
$missionEnginePath = Join-Path $scriptDir "Jarvis-MissionEngine.ps1"

$missionEngineCode = @'
param(
    [string]$Project = "",
    [int]$Limit = 5
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir   = Split-Path $scriptDir -Parent

. "$scriptDir\\Jarvis-LoadEnv.ps1"

$supabaseUrl  = $env:SUPABASE_URL
$serviceKey   = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $supabaseUrl -or -not $serviceKey) {
    throw "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set in environment."
}

$headers = @{
    apikey        = $serviceKey
    Authorization = "Bearer $serviceKey"
}

Write-Host "=== Jarvis-MissionEngine ==="

$missionsUrl = "$supabaseUrl/rest/v1/az_missions?select=*&status=eq.queued"

if ($Project) {
    $missionsUrl += "&project=eq.$Project"
}

$missionsUrl += "&limit=$Limit"

$missions = Invoke-RestMethod -Method Get -Uri $missionsUrl -Headers $headers

if (-not $missions) {
    Write-Host "No queued missions found."
    exit 0
}

foreach ($mission in $missions) {
    Write-Host ""
    Write-Host "Processing mission #$($mission.id): $($mission.title) [$($mission.project)]"

    $patchBody = @{ status = "planning" } | ConvertTo-Json
    Invoke-RestMethod -Method Patch `
        -Uri "$supabaseUrl/rest/v1/az_missions?id=eq.$($mission.id)" `
        -Headers $headers -ContentType "application/json" -Body $patchBody | Out-Null

    $systemPrompt = @"
You are MissionPlannerAgent for AION-ZERO.
Given a mission goal and context, break it into an ordered list of steps.

Return STRICT JSON ONLY (no prose), with this shape:

{
  "steps": [
    {
      "description": "string, what to do",
      "risk_level": "low|medium|high|critical",
      "requires_approval": true or false,
      "suggested_action": "code|deploy|config|docs|infra|bootstrap|plan"
    }
  ]
}
"@

    $userPrompt = @"
Mission:
- Project: $($mission.project)
- Title: $($mission.title)
- Goal: $($mission.goal)
- Global risk level: $($mission.risk_level)
- Autopilot mode: $($mission.autopilot_mode)

Rules:
- Mark steps that change production DB, auth, billing, or live traffic as 'high' or 'critical'.
- For high/critical steps, set requires_approval = true.
- Keep 4-12 steps maximum.
"@

    $jsonText = powershell -NoProfile -ExecutionPolicy Bypass `
        -File "$scriptDir\\Jarvis-BrainRouter.ps1" `
        -BrainId "deepseek-reasoner" `
        -SystemPrompt $systemPrompt `
        -UserPrompt $userPrompt

    try {
        $plan = $jsonText | ConvertFrom-Json
    }
    catch {
        Write-Warning "Failed to parse DeepSeek mission plan JSON for mission #$($mission.id)."
        Write-Host $jsonText
        $failBody = @{ status = "failed" } | ConvertTo-Json
        Invoke-RestMethod -Method Patch `
            -Uri "$supabaseUrl/rest/v1/az_missions?id=eq.$($mission.id)" `
            -Headers $headers -ContentType "application/json" -Body $failBody | Out-Null
        continue
    }

    if (-not $plan.steps) {
        Write-Warning "No steps returned for mission #$($mission.id)."
        $failBody = @{ status = "failed" } | ConvertTo-Json
        Invoke-RestMethod -Method Patch `
            -Uri "$supabaseUrl/rest/v1/az_missions?id=eq.$($mission.id)" `
            -Headers $headers -ContentType "application/json" -Body $failBody | Out-Null
        continue
    }

    $stepIndex = 0
    foreach ($step in $plan.steps) {
        $stepIndex++

        $stepRisk   = if ($step.risk_level) { $step.risk_level } else { $mission.risk_level }
        $needsApproval = $false

        if ($step.requires_approval -eq $true) {
            $needsApproval = $true
        }
        elseif ($stepRisk -in @("high","critical") -and $mission.autopilot_mode -eq "approval_required") {
            $needsApproval = $true
        }

        $action = if ($step.suggested_action) { $step.suggested_action } else { "plan" }

        $mode = if ($stepRisk -in @("high","critical")) { "simulate" } else { "execute" }

        $cmdBody = @(
            @{
                project     = $mission.project
                action      = $action
                status      = "queued"
                risk_level  = $stepRisk
                profile     = "default"
                mode        = $mode
                description = $step.description
                brain_id    = $null
            }
        ) | ConvertTo-Json

        $cmdResp = Invoke-RestMethod -Method Post `
            -Uri "$supabaseUrl/rest/v1/az_commands" `
            -Headers $headers -ContentType "application/json" -Body $cmdBody

        $commandId = $cmdResp[0].id

        $stepBody = @(
            @{
                mission_id        = $mission.id
                step_index        = $stepIndex
                description       = $step.description
                risk_level        = $stepRisk
                status            = "queued"
                requires_approval = $needsApproval
                command_id        = $commandId
            }
        ) | ConvertTo-Json

        Invoke-RestMethod -Method Post `
            -Uri "$supabaseUrl/rest/v1/az_mission_steps" `
            -Headers $headers -ContentType "application/json" -Body $stepBody | Out-Null

        Write-Host "  Step $stepIndex: $($step.description) (risk=$stepRisk, approval=$needsApproval) -> command #$commandId"
    }

    $hasApprovalSteps = $plan.steps | Where-Object {
        $_.requires_approval -eq $true
    }

    $newStatus = if ($hasApprovalSteps) { "waiting_approval" } else { "running" }

    $missionDoneBody = @{ status = $newStatus } | ConvertTo-Json
    Invoke-RestMethod -Method Patch `
        -Uri "$supabaseUrl/rest/v1/az_missions?id=eq.$($mission.id)" `
        -Headers $headers -ContentType "application/json" -Body $missionDoneBody | Out-Null

    Write-Host "Mission #$($mission.id) planned. Status -> $newStatus"
}
'@

Set-Content -Path $missionEnginePath -Value $missionEngineCode -Encoding UTF8
Write-Host "Wrote mission engine: $missionEnginePath"

Write-Host "=== Setup complete. Next: create a mission row and run Jarvis-MissionEngine once. ==="
