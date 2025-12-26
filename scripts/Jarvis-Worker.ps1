<#
    Jarvis-Worker.ps1
    -----------------
    The Unified "Brain" Worker.
    Polls az_commands for ANY queued command.
    Routes to specific agent script based on 'action'.
#>

$ErrorActionPreference = "Stop"

Write-Host "`n=== JARVIS UNIFIED WORKER ==="
Write-Host "Initializing..."

# 1. LOAD ENV
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
. "$ScriptDir\Jarvis-LoadEnv.ps1"

$SupabaseUrl = $env:SUPABASE_URL
$ServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY
if ([string]::IsNullOrWhiteSpace($ServiceKey)) { $ServiceKey = $env:SUPABASE_SERVICE_KEY }
$PollSeconds = 5

if (-not $SupabaseUrl -or -not $ServiceKey) {
    throw "CRITICAL: Supabase credentials missing."
}

$Headers = @{
    apikey        = $ServiceKey
    Authorization = "Bearer $ServiceKey"
    Accept        = "application/json"
}

# 2. AGENT REGISTRY
$Agents = @{
    "code"   = "$ScriptDir\Jarvis-CodeAgent.ps1"
    "sql"    = "$ScriptDir\Jarvis-RunAutoSql.ps1"
    "notify" = "$ScriptDir\Jarvis-NotifyWorker.ps1"
    "ops"    = "$ScriptDir\Jarvis-LocalOps.ps1"
    "hr"     = "F:\AION-ZERO\titan-hr\Jarvis-HR-Validator.ps1"
}

function Get-NextCommand {
    # Fetch oldest queued command of ANY supported type
    # Construct filter: action=in.(code,sql,notify,ops,hr)
    $filter = "code,sql,notify,ops,hr"
    $url = "$SupabaseUrl/rest/v1/az_commands?select=*&status=eq.queued&action=in.($filter)&order=created_at.asc&limit=1"
    
    try {
        $resp = Invoke-RestMethod -Method Get -Uri $url -Headers $Headers
        if ($resp -is [System.Array] -and $resp.Count -gt 0) { return $resp[0] }
        return $null
    }
    catch {
        Write-Warning "Poll failed: $($_.Exception.Message)"
        return $null
    }
}

Write-Host "Listening for commands... (actions: $($Agents.Keys -join ', '))"

# 3. MAIN LOOP
while ($true) {
    $cmd = Get-NextCommand
    
    if ($cmd) {
        $id = $cmd.id
        $action = $cmd.action
        $script = $Agents[$action]
        
        Write-Host "`n[JARVIS] Picked Command #$id (Action: $action)" -ForegroundColor Cyan
        
        if ($script -and (Test-Path $script)) {
            Write-Host " -> Dispatching to $script..." -ForegroundColor DarkGray
            
            # Execute Child Agent in-process (using & operator)
            # We pass -SingleRun and -CommandId logic
            try {
                & $script -CommandId $id -SingleRun
            }
            catch {
                Write-Error "Agent Execution Failed: $_"
                # Ideally mark command as error if agent crashed without handling it
            }
            
            Write-Host " -> Done." -ForegroundColor Green
        }
        else {
            Write-Warning "No agent script found for action '$action'. Skipping/Flagging."
            # Optional: Mark as error in DB to prevent infinite loop
        }
    }
    else {
        # Heartbeat or idle log could go here
        Start-Sleep -Seconds $PollSeconds
    }
}
