<#
    Jarvis-CodeAgent.ps1
    --------------------
    Robust, Safe, Autonomous Coding Agent.
    Polls az_commands, queries Ollama, validates JSON, checks safety, and applies patches.
#>

param(
    [string]$Project,
    [string]$Model,
    [bool]$AutoApply = $true,
    [int]$CommandId = 0,
    [switch]$SingleRun
)

$ErrorActionPreference = "Stop"

# --- 1. SETUP & ENV ----------------------------------------------------------

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path $scriptDir -Parent
Write-Host "=== Jarvis-CodeAgent ($Project) ==="
Write-Host "RepoRoot : $repoRoot"
Write-Host "Mode     : $(if($AutoApply){'AUTO-APPLY'}else{'PROPOSE-ONLY'})"

# Load Env (enforces Panic Lock)
. "$scriptDir\Jarvis-LoadEnv.ps1"

# Mesh heartbeat helper
. "$scriptDir\Jarvis-MeshHeartbeat.ps1"

# Load Ledger (enforces Budget Cap)
. "$scriptDir\Jarvis-Ledger.ps1"

# Check Budget immediately (skip if just single run? No, always enforce budget)
if ($Project -and -not (Test-Budget -Project $Project)) {
    throw "BLOCK: Daily budget for '$Project' exceeded. No new LLM calls."
}

$supabaseUrl = $env:SUPABASE_URL
$serviceKey = $env:SUPABASE_SERVICE_ROLE_KEY
if (-not $serviceKey) { $serviceKey = $env:SUPABASE_SERVICE_KEY }
$ollamaUrl = $env:OLLAMA_HOST
if (-not $ollamaUrl) { $ollamaUrl = "http://127.0.0.1:11434" }

if (-not $supabaseUrl -or -not $serviceKey) {
    throw "CRITICAL: Supabase credentials missing."
}

$sbHeaders = @{
    apikey        = $serviceKey
    Authorization = "Bearer $serviceKey"
    Prefer        = "return=representation"
}

# --- 2. SAFETY DEFINITIONS ---------------------------------------------------

$ProtectedFiles = @(
    "Panic-Stop.ps1",
    "Jarvis-Watchdog.ps1",
    "Jarvis-LoadEnv.ps1",
    "Jarvis-Ledger.ps1",
    ".env",
    "JARVIS.PANIC.LOCK"
)

function Test-PathSafety {
    param([string]$RelPath)
    
    # 1. Block protected filenames
    $leaf = Split-Path $RelPath -Leaf
    if ($ProtectedFiles -contains $leaf) {
        throw "SAFETY VIOLATION: Attempt to edit protected file '$leaf'"
    }

    # 2. Block traversal
    if ($RelPath -match "\.\.") {
        throw "SAFETY VIOLATION: Path traversal detected in '$RelPath'"
    }

    return $true
}

function Invoke-Speak {
    param([string]$Text)
    $VoiceScript = "$scriptDir\Jarvis-Voice.ps1"
    if (Test-Path $VoiceScript) {
        # Using Start-Process to avoid blocking the agent while speaking
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$VoiceScript`" -Text `"$Text`"" -WindowStyle Hidden
    }
}

function Convert-TextToJson {
    param([string]$Text)

    if (-not $Text) { return $null }
    
    # Regex to find the outer-most JSON object { ... }
    if ($Text -match "(?ms)(\{.*\})") {
        return $Matches[1]
    }
    return $Text 
}

function Test-AgentSchema {
    param([object]$Json)

    if (-not $Json.summary) { throw "Schema Error: Missing 'summary'" }
    if (-not $Json.files -or $Json.files.Count -eq 0) { throw "Schema Error: 'files' array is empty/missing" }
    
    foreach ($f in $Json.files) {

        if (-not $f.path) { throw "Schema Error: File missing 'path'" }
        if (-not $f.mode) { throw "Schema Error: File missing 'mode'" }
        if (-not $f.patch) { throw "Schema Error: File missing 'patch'" }
    }
}

# --- 3. SUPABASE HELPERS -----------------------------------------------------

function Update-Command {
    param([int]$Id, [hashtable]$Fields)
    $body = $Fields | ConvertTo-Json -Depth 10
    Invoke-RestMethod -Method Patch -Uri "$supabaseUrl/rest/v1/az_commands?id=eq.$Id" `
        -Headers $sbHeaders -ContentType "application/json" -Body $body | Out-Null
}

function Get-QueuedCommands {
    param([int]$TargetId = 0)
    
    if ($TargetId -gt 0) {
        $url = "$supabaseUrl/rest/v1/az_commands?select=*&id=eq.$TargetId"
    }
    else {
        $url = "$supabaseUrl/rest/v1/az_commands?select=*&project=eq.$Project&action=eq.code&status=eq.queued&order=id.asc"
    }
    
    $resp = Invoke-RestMethod -Method Get -Uri $url -Headers $sbHeaders
    if ($resp -is [System.Array]) { return $resp }
    if ($resp) { return @($resp) }
    return @()
}

# --- 4. CORE OLLAMA LOGIC ----------------------------------------------------

function Build-Prompt {
    param($Instruction, $Arguments)
    return @"
You are Jarvis CodeAgent.
Instruction: $Instruction
Context: $Arguments

Return ONLY valid JSON. No markdown. No explanations.
Schema:
{
  "summary": "string",
  "files": [
    { "path": "path/matched/to/repo.ext", "mode": "replace", "patch": "FULL_NEW_CONTENT" }
  ]
}
"@
}

function Invoke-Model {
    param([int]$CmdId, [string]$Prompt, [string]$AgentModel)
    
    $effectiveModel = if ($AgentModel) { $AgentModel } else { "llama3" } # Default fallback

    $payload = @{
        model  = $effectiveModel
        prompt = $Prompt
        stream = $false
        format = "json"
    } | ConvertTo-Json -Depth 10
    
    Write-Host "[LLM] Sending prompt to $effectiveModel..."
    
    # Simple cost estimate: $5.00 / 1M chars input/output
    $ratePerChar = 0.000005 
    
    try {
        $resp = Invoke-RestMethod -Method Post -Uri "$ollamaUrl/api/generate" -ContentType "application/json" -Body $payload
        $raw = $resp.response
        Write-Host "[LLM] Received $(($raw.Length)) chars."
        
        # LOG COST
        $chars = $Prompt.Length + $raw.Length
        $cost = $chars * $ratePerChar
        
        Add-LedgerEntry -Project $Project -Agent "code_agent" `
            -Operation "llm_$effectiveModel" -Cost $cost `
            -HardCost @{ chars = $chars } -CommandId $CmdId

        $jsonText = Convert-TextToJson -Text $raw
        $data = $jsonText | ConvertFrom-Json
        
        Test-AgentSchema -Json $data
        return $data
    }
    catch {
        throw "Model Error: $($_.Exception.Message)"
    }
}

# --- 5. MAIN LOOP ------------------------------------------------------------

while ($true) {
    if ($SingleRun -and $CommandId -gt 0) {
        $cmds = Get-QueuedCommands -TargetId $CommandId
    }
    else {
        $cmds = Get-QueuedCommands
    }

    if ($cmds.Count -eq 0) {
        if ($SingleRun) { 
            Write-Warning "Command #$CommandId not found or not accessible."
            exit 
        }
        Write-Host "No queued commands. Waiting..."
        Start-Sleep -Seconds 10
        continue
    }

    foreach ($cmd in $cmds) { 
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            # --- HEARTBEAT START ---
            . "$scriptDir\Jarvis-MeshHeartbeat.ps1" -AgentName "Jarvis-CodeAgent" -Status "working"
            
            $id = $cmd.id
            $currentProject = $cmd.project 
            if (-not $currentProject) { $currentProject = $Project }

            Write-Host ">>> Processing Command #$id for Project: $currentProject"
            
            # Re-check budget before every command in loop using the Command's project
            if (-not (Test-Budget -Project $currentProject)) {
                Write-Warning "Daily budget for '$currentProject' reached. Stopping/Skipping."
                # If single run, explicit failure
                if ($SingleRun) { throw "Budget Exceeded for $currentProject" }
                break 
            }
        
            Update-Command -Id $id -Fields @{ status = "in_progress"; picked_at = (Get-Date).ToString("o") }
            
            # 1. GENERATE
            # Use Model from param or default if not passed, but maybe command args has model preference?
            $plan = Invoke-Model -CmdId $id -Prompt (Build-Prompt -Instruction $cmd.instruction -Arguments $cmd.args) -AgentModel $Model
            Write-Host "Plan: $($plan.summary)" -ForegroundColor Cyan
            
            # 2. VALIDATE SAFETY
            foreach ($file in $plan.files) {
                Test-PathSafety -RelPath $file.path
            }
            
            # 3. APPLY (If AutoApply check global param or maybe command override?)
            if ($AutoApply) {
                foreach ($file in $plan.files) {
                    $fullPath = Join-Path $repoRoot $file.path
                    $dir = Split-Path $fullPath
                    if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
                    
                    Set-Content -Path $fullPath -Value $file.patch -Encoding UTF8
                    
                    # INJECT FINGERPRINT (AION-ZERO SIGNATURE)
                    python "$scriptDir\..\py\fingerprint.py" sign "$fullPath"
                    
                    Write-Host " [WRITE+SIGN] $fullPath" -ForegroundColor Green
                }
                
                Update-Command -Id $id -Fields @{ 
                    status      = "completed"
                    result_json = ($plan | ConvertTo-Json -Depth 10)
                    updated_at  = (Get-Date).ToString("o")
                }
                # Speak-Status "Task Complete. System Updated."
            }
            else {
                Write-Host " [PROPOSE] Action required to apply." -ForegroundColor Yellow
                Update-Command -Id $id -Fields @{ 
                    status      = "proposed"
                    result_json = ($plan | ConvertTo-Json -Depth 10)
                    updated_at  = (Get-Date).ToString("o")
                }
            }
            
            $sw.Stop()
            . "$scriptDir\Jarvis-MeshHeartbeat.ps1" -AgentName "Jarvis-CodeAgent" -Status "active" -LatencyMs $sw.ElapsedMilliseconds

        }
        catch {
            $sw.Stop()
            Write-Warning "Failed Step: $($_.Exception.Message)"
            
            # Report Error Heartbeat
            . "$scriptDir\Jarvis-MeshHeartbeat.ps1" -AgentName "Jarvis-CodeAgent" -Status "error" -LatencyMs $sw.ElapsedMilliseconds
            
            Update-Command -Id $id -Fields @{ status = "error"; error_message = $_.Exception.Message }
        }
    }

    if ($SingleRun) { break }
}
