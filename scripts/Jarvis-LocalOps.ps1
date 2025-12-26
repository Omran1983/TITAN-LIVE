<#
    Jarvis-LocalOps.ps1
    -------------------
    Executes 'ops' commands (Shell/PowerShell) from az_commands.
#>

param(
    [int]$CommandId = 0,
    [switch]$SingleRun
)

$ErrorActionPreference = "Stop"

# Load Env
. "F:\AION-ZERO\scripts\Jarvis-LoadEnv.ps1"

$SupabaseUrl = $env:SUPABASE_URL
$ServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY
if ([string]::IsNullOrWhiteSpace($ServiceKey)) { $ServiceKey = $env:SUPABASE_SERVICE_KEY }
$Headers = @{
    apikey         = $ServiceKey
    Authorization  = "Bearer $ServiceKey"
    "Content-Type" = "application/json"
}

function Update-Command {
    param([int]$Id, [hashtable]$Fields)
    $body = $Fields | ConvertTo-Json -Depth 5
    Invoke-RestMethod -Method Patch -Uri "$SupabaseUrl/rest/v1/az_commands?id=eq.$Id" `
        -Headers $Headers -Body $body | Out-Null
}

function Process-OpsCommand {
    param([PSCustomObject]$cmd)
    
    $id = $cmd.id
    $instruction = $cmd.instruction # The shell command to run
    
    Write-Host ">>> Processing Ops #$($id): $instruction" -ForegroundColor Cyan
    Update-Command -Id $id -Fields @{ status = "in_progress"; picked_at = (Get-Date).ToString("o") }

    try {
        # Execute the instruction as a simplified shell command
        # Security Note: This runs almost anything.
        
        $output = Invoke-Expression $instruction 2>&1 | Out-String
        
        Write-Host "Output: $output" -ForegroundColor Gray
        
        Update-Command -Id $id -Fields @{ 
            status      = "completed"
            result_json = (@{ output = $output } | ConvertTo-Json)
            updated_at  = (Get-Date).ToString("o")
        }
    }
    catch {
        Write-Error "Ops Failed: $_"
        Update-Command -Id $id -Fields @{ 
            status        = "error"
            error_message = $_.Exception.Message
            updated_at    = (Get-Date).ToString("o")
        }
    }
}

while ($true) {
    if ($SingleRun -and $CommandId -gt 0) {
        $url = "$SupabaseUrl/rest/v1/az_commands?select=*&id=eq.$CommandId"
        $res = Invoke-RestMethod -Method Get -Uri $url -Headers $Headers
        if ($res.Count -gt 0) { Process-OpsCommand -cmd $res[0] }
        else { Write-Warning "Ops command #$CommandId not found." }
        break
    }
    
    # Polling mode (if run directly)
    $url = "$SupabaseUrl/rest/v1/az_commands?select=*&action=eq.ops&status=eq.queued&limit=1"
    $cmds = Invoke-RestMethod -Method Get -Uri $url -Headers $Headers
    
    if ($cmds.Count -gt 0) {
        Process-OpsCommand -cmd $cmds[0]
    }
    else {
        Start-Sleep -Seconds 10
    }
}
