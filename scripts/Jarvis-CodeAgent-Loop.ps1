<#
    Jarvis-CodeAgent.ps1
    --------------------
    Polls az_commands for queued "code" actions for a given project,
    calls Ollama with a structured prompt, and writes the result JSON
    back into az_commands.result_json / status.

    Usage:

      cd F:\AION-ZERO\scripts
      powershell -NoProfile -ExecutionPolicy Bypass -File .\Jarvis-CodeAgent.ps1 `
        -Project "reachx" `
        -Model "qwen2.5-coder:7b"
#>

param(
    [Parameter(Mandatory = $true)][string]$Project,
    [Parameter(Mandatory = $true)][string]$Model
)

$ErrorActionPreference = "Stop"

Write-Host "=== Jarvis-CodeAgent ($Project) starting ==="

# Resolve dirs
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path $scriptDir -Parent
Write-Host "ScriptDir: $scriptDir"
Write-Host "RepoRoot : $repoRoot"

# Load env
. "$scriptDir\Jarvis-LoadEnv.ps1"

# Supabase env
$supabaseUrl = $env:SUPABASE_URL
$serviceKey  = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $supabaseUrl -or -not $serviceKey) {
    throw "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set in environment."
}

$sbHeaders = @{
    apikey        = $serviceKey
    Authorization = "Bearer $serviceKey"
    Prefer        = "return=representation"
}

# Ollama env
$ollamaUrl = $env:OLLAMA_HOST
if (-not $ollamaUrl -or $ollamaUrl.Trim() -eq "") {
    $ollamaUrl = "http://127.0.0.1:11434"
}
Write-Host "[CodeAgent] Using Ollama at $ollamaUrl with model '$Model'"

function Update-Command {
    param(
        [Parameter(Mandatory)][int]$Id,
        [hashtable]$Fields
    )

    $body = @($Fields) | ConvertTo-Json -Depth 10
    $url  = "$supabaseUrl/rest/v1/az_commands?id=eq.$Id"

    Invoke-RestMethod -Method Patch `
        -Uri $url `
        -Headers $sbHeaders `
        -ContentType "application/json" `
        -Body $body | Out-Null
}

function Get-QueuedCommands {
    param(
        [Parameter(Mandatory)][string]$Project
    )

    $url = "$supabaseUrl/rest/v1/az_commands" +
           "?select=*" +
           "&project=eq.$Project" +
           "&action=eq.code" +
           "&status=eq.queued" +
           "&order=id.asc"

    Write-Host "[CodeAgent] Fetching commands from:"
    Write-Host "  $url"

    $resp = Invoke-RestMethod -Method Get `
        -Uri $url `
        -Headers $sbHeaders

    if ($resp -is [System.Array]) { return $resp }
    if ($resp) { return @($resp) }
    return @()
}

function Build-CodePrompt {
    param(
        [string]$ProjectName,
        [string]$Instruction,
        [string]$Args
    )

    if (-not $Instruction) {
        $Instruction = ""
    }

    $prompt = @"
You are Jarvis CodeAgent working on project '$ProjectName'.

Your job:
- Read the instruction and args.
- Decide which files to touch.
- Generate patches to apply.

Instruction:

$Instruction

Args (JSON):
$Args

You MUST respond ONLY with a JSON object in this exact shape (NO code fences, NO markdown):

{
  "summary": "1-3 lines summary of the change",
  "files": [
    {
      "path": "relative/path/from/repo/root.ext",
      "mode": "patch_or_replace",
      "patch": "for 'replace', the full new file content; for 'patch', a unified diff"
    }
  ]
}

Rules:
- Do NOT wrap the response in ```json or any other code fences.
- Do NOT include any explanations outside this JSON.
- 'path' is always relative to the project repo root: $repoRoot
- If unsure, use "replace" mode and provide full file content in 'patch'.
"@

    return $prompt
}

function Clean-ModelJson {
    param(
        [string]$Raw
    )

    if (-not $Raw) { return $null }

    $clean = $Raw.Trim()

    # Strip markdown fences like ```json ... ``` if present
    $lines = $clean -split "`n"

    if ($lines.Count -gt 0 -and $lines[0].Trim().StartsWith("```")) {
        if ($lines.Count -gt 1) {
            $lines = $lines[1..($lines.Count - 1)]
        } else {
            $lines = @()
        }
    }

    if ($lines.Count -gt 0 -and $lines[$lines.Count - 1].Trim().StartsWith("```")) {
        if ($lines.Count -gt 1) {
            $lines = $lines[0..($lines.Count - 2)]
        } else {
            $lines = @()
        }
    }

    $clean = ($lines -join "`n").Trim()
    return $clean
}

function Call-OllamaForCommand {
    param(
        [int]$CommandId,
        [string]$Prompt
    )

    $bodyHash = @{
        model  = $Model
        prompt = $Prompt
        stream = $false
        format = "json"   # ask Ollama for strict JSON
    }

    $bodyJson = $bodyHash | ConvertTo-Json -Depth 10

    Write-Host "[CodeAgent] Ollama /api/generate JSON body:"
    Write-Host $bodyJson

    $url = "$ollamaUrl/api/generate"

    try {
        $resp = Invoke-RestMethod -Method Post `
            -Uri $url `
            -ContentType "application/json" `
            -Body $bodyJson

        # Ollama returns: { model, created_at, response, done, ... }
        $rawText = [string]$resp.response

        Write-Host "[CodeAgent] Raw model output (truncated to 300 chars):"
        if ($rawText.Length -gt 300) {
            Write-Host ($rawText.Substring(0, 300) + "...")
        } else {
            Write-Host $rawText
        }

        $clean = Clean-ModelJson -Raw $rawText
        if (-not $clean) {
            throw "Empty model JSON after cleaning."
        }

        try {
            $parsed = $clean | ConvertFrom-Json
        }
        catch {
            throw "[CodeAgent] Failed to parse model JSON for id=$CommandId: $($_.Exception.Message)"
        }

        return $parsed
    }
    catch {
        $errMsg = $_.ToString()
        Write-Warning $errMsg
        throw $errMsg
    }
}

# === Main ===

$commands = Get-QueuedCommands -Project $Project

if ($commands.Count -eq 0) {
    Write-Host "[CodeAgent] No queued commands for project '$Project'. Exiting."
    return
}

foreach ($cmd in $commands) {
    $commandId  = [int]$cmd.id
    $args       = [string]$cmd.args
    $instruction = ""   # no 'instruction' column in az_commands

    Write-Host ""
    Write-Host "=== Processing command #$commandId ==="
    Write-Host "Instruction:"
    Write-Host $instruction
    Write-Host "Args       : $args"
    Write-Host ""

    # Mark in_progress
    try {
        Update-Command -Id $commandId -Fields @{
            status        = "in_progress"
            picked_at     = (Get-Date).ToString("o")
            error_message = $null
        }
        Write-Host "[CodeAgent] Marked id=$commandId as in_progress."
    }
    catch {
        Write-Warning "[CodeAgent] Failed to mark id=$commandId as in_progress: $($_.Exception.Message)"
        continue
    }

    $resultJson = $null
    $hadError   = $false
    $errorMsg   = $null

    # Build prompt & call model
    $prompt = Build-CodePrompt -ProjectName $Project -Instruction $instruction -Args $args

    try {
        $parsed = Call-OllamaForCommand -CommandId $commandId -Prompt $prompt
        $resultJson = $parsed | ConvertTo-Json -Depth 10
    }
    catch {
        $hadError = $true
        $errorMsg = $_.ToString()
        Write-Warning $errorMsg
    }

    # Update command with result
    try {
        if ($hadError) {
            Update-Command -Id $commandId -Fields @{
                status        = "error"
                error_message = $errorMsg
                updated_at    = (Get-Date).ToString("o")
            }
        }
        else {
            Update-Command -Id $commandId -Fields @{
                status      = "completed"
                result_json = $resultJson
                updated_at  = (Get-Date).ToString("o")
            }
        }

        # Debug: re-fetch row to show final state
        $debugUrl = "$supabaseUrl/rest/v1/az_commands?select=*&id=eq.$commandId"
        $debugRow = Invoke-RestMethod -Method Get -Uri $debugUrl -Headers $sbHeaders
        $debugRow
    }
    catch {
        Write-Warning "[CodeAgent] Failed to update id=$commandId final status: $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "[CodeAgent] All queued commands processed for project '$Project'."
