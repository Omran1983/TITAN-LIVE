# Jarvis-ReflexEngine.ps1
# -----------------------------------------------------------------------------
# THE IMMUNE SYSTEM ACTUATOR
# -----------------------------------------------------------------------------
# Role: 
# 1. Runs periodically (every 5 mins).
# 2. Checks system health via Python Doctor.
# 3. EXECUTES physical repairs (Restarts, File Reverts, Alerts).
# -----------------------------------------------------------------------------

param(
    [string]$Mode = "Auto" # Auto = Fix it, Audit = Just Log it
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile = Join-Path $ScriptDir "Jarvis-Reflex.log"
. "$ScriptDir\Jarvis-LoadEnv.ps1"

function Write-Log {
    param([string]$Msg)
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] $Msg"
    Write-Host $line -ForegroundColor Cyan
    Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
}

Write-Log "=== REFLEX ENGINE STARTED ($Mode) ==="

# 1. Define Critical Components to Check
$Components = @("Jarvis-CommandsApi", "Jarvis-GraphBuilderWorker", "Jarvis-Watchdog")

# 2. Iterate and Consult Doctor
foreach ($Comp in $Components) {
    # Check Status
    $Code = 0
    try {
        $Task = Get-ScheduledTask -TaskName $Comp -ErrorAction Stop
        $Info = $Task | Get-ScheduledTaskInfo
        $Code = $Info.LastTaskResult
    }
    catch {
        $Code = -1 # Missing
    }

    # If Failed (Non-Zero and Not Running)
    # 267009 = Running, 0 = Success
    if ($Code -ne 0 -and $Code -ne 267009 -and $Code -ne 0x41301) {
        Write-Log "INCIDENT: $Comp is failing (Code $Code)."
        
        # CONSULT DOCTOR (Python)
        try {
            # Pass the error code as the 'error signature'
            $Json = python "$ScriptDir\..\py\reflex_engine.py" --component "$Comp" --error "Task Failed Code $Code" --logs "LastRun: $($Info.LastRunTime)"
            $Plan = $Json | ConvertFrom-Json
            
            Write-Log "DOCTOR: Action='$($Plan.action)' Reason='$($Plan.reason)'"
            
            # EXECUTE CURE
            if ($Mode -eq "Auto") {
                switch ($Plan.action) {
                    "restart" {
                        Write-Log "ACTUATOR: Restarting $Comp..."
                        Start-ScheduledTask -TaskName $Comp
                    }
                    "restart_service" {
                        Write-Log "ACTUATOR: Restarting Service $Comp..."
                        Start-ScheduledTask -TaskName $Comp
                    }
                    "escalate" {
                        Write-Log "ACTUATOR: Escalating to Admin (Notification)."
                        # TODO: Call Notification API
                    }
                    "patch" {
                        Write-Log "ACTUATOR: 🚑 SURGICAL INTERVENTION REQUIRED."
                        Write-Log "Instruction: $($Plan.params.instruction)"
                        
                        # POST Command to CodeAgent
                        $CmdBody = @{
                            project     = "AION-ZERO"
                            instruction = "REFLEX REPAIR: " + $Plan.params.instruction
                            status      = "queued"
                            action      = "code"
                            origin      = "reflex_autofix"
                        } | ConvertTo-Json -Depth 5
                        
                        $url = $env:SUPABASE_URL
                        $key = $env:SUPABASE_SERVICE_ROLE_KEY
                        $headers = @{ apikey = $key; Authorization = "Bearer $key" }
                        
                        Invoke-RestMethod -Method Post -Uri "$url/rest/v1/az_commands" -Headers $headers -Body $CmdBody -ContentType "application/json"
                        Write-Log "ACTUATOR: Patch job dispatched to Surgeon (CodeAgent)."
                    }
                    default {
                        Write-Log "ACTUATOR: No automated action for this diagnosis."
                    }
                }
            }
        }
        catch {
            Write-Log "ERROR: Doctor is brain-dead (Python script failed): $($_.Exception.Message)"
        }
    }
}

Write-Log "=== REFLEX ENGINE FINISHED ==="
