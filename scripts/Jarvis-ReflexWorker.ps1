<# 
    Jarvis-ReflexWorker.ps1
    ------------------------
    Lightweight reflex engine for AION-ZERO.

    Responsibilities:
      - Poll az_mesh_agents for stale/offline agents
      - Decide if any agent should be restarted
      - Log reflex actions (for now: Write-Host, later: Supabase log)

    Run as a Scheduled Task every 1–2 minutes OR in a background loop.
#>

$ErrorActionPreference = "SilentlyContinue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Ensure Env Loaded
if (Test-Path "$ScriptDir\Jarvis-LoadEnv.ps1") {
    . "$ScriptDir\Jarvis-LoadEnv.ps1"
}

function Get-SupabaseConfig {
    $supabaseUrl = if ($env:AZ_SUPABASE_URL) { $env:AZ_SUPABASE_URL } else { $env:SUPABASE_URL }
    $supabaseKey = if ($env:AZ_SUPABASE_SERVICE_KEY) { $env:AZ_SUPABASE_SERVICE_KEY } else { $env:SUPABASE_SERVICE_ROLE_KEY }

    if (-not $supabaseUrl -or -not $supabaseKey) {
        throw "Supabase env vars missing."
    }

    return @{
        Url = $supabaseUrl
        Key = $supabaseKey
    }
}

function Write-ReflexLog {
    param(
        [string] $AgentName,
        [string] $Action,
        [string] $Reason,
        [hashtable] $Details = @{}
    )

    try {
        $cfg = Get-SupabaseConfig
        $tableUrl = "$($cfg.Url)/rest/v1/az_reflex_log"

        $headers = @{
            "apikey"        = $cfg.Key
            "Authorization" = "Bearer $($cfg.Key)"
            "Content-Type"  = "application/json"
        }

        $payload = @{
            agent_name = $AgentName
            action     = $Action
            reason     = $Reason
            details    = $Details
        }

        $json = $payload | ConvertTo-Json -Depth 5

        Invoke-RestMethod -Method Post -Uri $tableUrl -Headers $headers -Body $json | Out-Null
    }
    catch {
        Write-Host "[REFLEX LOG] Failed: $($_.Exception.Message)" -ForegroundColor DarkYellow
    }
}

function Get-MeshAgents {
    param(
        [int] $Limit = 100
    )

    $cfg = Get-SupabaseConfig
    $tableUrl = "$($cfg.Url)/rest/v1/az_mesh_agents?order=last_seen.desc&limit=$Limit"

    $headers = @{
        "apikey"        = $cfg.Key
        "Authorization" = "Bearer $($cfg.Key)"
        "Content-Type"  = "application/json"
    }

    $res = Invoke-RestMethod -Method Get -Uri $tableUrl -Headers $headers
    return $res
}

function Restart-AgentIfNeeded {
    param(
        [string] $AgentName,
        [datetime] $LastSeen,
        [string] $Status
    )

    # Threshold: if last_seen older than 2 minutes, consider it stale
    $threshold = (Get-Date).AddMinutes(-2)

    if ($LastSeen -lt $threshold -or $Status -eq "error") {
        Write-Host "[REFLEX] $AgentName is stale or error (last_seen=$LastSeen, status=$Status)."

        $script = ""
        switch ($AgentName) {
            "Jarvis-CodeAgent" {
                $script = "$ScriptDir\Jarvis-CodeAgent.ps1"
            }
            "Jarvis-Watchdog" {
                $script = "$ScriptDir\Jarvis-Watchdog.ps1"
            }
            "Jarvis-CommandsApi-Worker" {
                $script = "$ScriptDir\Jarvis-CommandsApi.ps1"
            }
            "CitadelServer" {
                # Special case for server (Python)
                $script = "$ScriptDir\..\citadel\server.py" 
            }
            default {
                # For unknown agents: log only for now
                Write-Host "[REFLEX] No restart mapping for $AgentName (log only)." -ForegroundColor Yellow
                Write-ReflexLog -AgentName $AgentName -Action "no-op" -Reason "no_restart_mapping" -Details @{
                    status    = $Status
                    last_seen = $LastSeen.ToString("o")
                }
                return
            }
        }

        # Check if Python or PowerShell
        # Note: server.py needs python launch
        if ($script.EndsWith(".py")) {
            if (Test-Path $script) {
                Write-Host "[REFLEX] Restarting $AgentName (Python)..." -ForegroundColor Cyan
                Write-ReflexLog -AgentName $AgentName -Action "restart" -Reason "stale_or_error" -Details @{
                    script    = $script
                    status    = $Status
                    last_seen = $LastSeen.ToString("o")
                }
                Start-Process "python" -ArgumentList "`"$script`"" -WindowStyle Hidden
            }
        }
        elseif (Test-Path $script) {
            Write-Host "[REFLEX] Restarting $AgentName via PowerShell..." -ForegroundColor Cyan
            Write-ReflexLog -AgentName $AgentName -Action "restart" -Reason "stale_or_error" -Details @{
                script    = $script
                status    = $Status
                last_seen = $LastSeen.ToString("o")
            }
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File `"$script`"" -WindowStyle Hidden
        }
        else {
            Write-Host "[REFLEX] Script not found for $AgentName at $script" -ForegroundColor Red
            Write-ReflexLog -AgentName $AgentName -Action "restart_failed" -Reason "script_missing" -Details @{
                script    = $script
                status    = $Status
                last_seen = $LastSeen.ToString("o")
            }
        }
    }
    else {
        # Healthy: no action
        # Write-Host "[REFLEX] $AgentName is healthy." -ForegroundColor DarkGray
    }
}

try {
    Write-Host "[REFLEX] Starting Reflex check..." -ForegroundColor Green

    $agents = Get-MeshAgents
    if (-not $agents) {
        Write-Host "[REFLEX] No agent rows returned from az_mesh_agents."
    }

    foreach ($a in $agents) {
        $name = $a.agent_name
        $status = $a.status
        $last_seen = $null

        # Try parse last_seen as datetime
        try {
            $last_seen = [datetime]::Parse($a.last_seen)
        }
        catch {
            $last_seen = (Get-Date).AddYears(-10)
        }

        Restart-AgentIfNeeded -AgentName $name -LastSeen $last_seen -Status $status
    }

    Write-Host "[REFLEX] Check complete."
}
catch {
    Write-Host "[REFLEX] ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
