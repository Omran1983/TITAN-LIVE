<#
    Jarvis-Ledger.ps1
    -----------------
    Financial Controller for AION-ZERO.
    Agents MUST import this and call Test-Budget before expensive ops.
#>

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\Jarvis-LoadEnv.ps1"

$SupabaseUrl = $env:SUPABASE_URL
$ServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY
$BudgetCap = if ($env:AZ_BUDGET_CAP_USD) { [double]$env:AZ_BUDGET_CAP_USD } else { 5.00 }

$LedgerHeaders = @{
    apikey         = $ServiceKey
    Authorization  = "Bearer $ServiceKey"
    Prefer         = "return=representation"
    "Content-Type" = "application/json"
}

function Add-LedgerEntry {
    param(
        [Parameter(Mandatory)][string]$Project,
        [Parameter(Mandatory)][string]$Agent,
        [Parameter(Mandatory)][string]$Operation,
        [Parameter(Mandatory)][double]$Cost,
        [hashtable]$HardCost = @{},
        [long]$CommandId = 0
    )

    $body = @{
        project   = $Project
        agent     = $Agent
        operation = $Operation
        cost_usd  = $Cost
        hard_cost = $HardCost
    }
    
    if ($CommandId -gt 0) { $body["command_id"] = $CommandId }

    try {
        Invoke-RestMethod -Method Post `
            -Uri "$SupabaseUrl/rest/v1/az_ledger" `
            -Headers $LedgerHeaders `
            -Body ($body | ConvertTo-Json -Depth 5) | Out-Null
            
        Write-Host "[LEDGER] Logged `$$Cost for $Operation" -ForegroundColor DarkGray
    }
    catch {
        Write-Warning "[LEDGER] Failed to log cost: $($_.Exception.Message)"
    }
}

function Test-Budget {
    param([string]$Project)
    
    # Check today's spend via view or sum
    # "Where created_at >= Today UTC"
    $today = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
    $url = "$SupabaseUrl/rest/v1/az_ledger?select=cost_usd&project=eq.$Project&created_at=gte.$today"
    
    try {
        $rows = Invoke-RestMethod -Method Get -Uri $url -Headers $LedgerHeaders
        $total = 0.0
        if ($rows) {
            if ($rows -is [double]) { $total = $rows } # Single value edge case
            elseif ($rows -is [System.Array]) {
                $rows | ForEach-Object { $total += [double]$_.cost_usd }
            }
        }
        
        if ($total -ge $BudgetCap) {
            Write-Warning "!!! BUDGET EXCEEDED !!!"
            Write-Warning "Project '$Project' used `$$total (Cap `$$BudgetCap)"
            return $false
        }
        
        $remaining = $BudgetCap - $total
        Write-Host "[BUDGET] Used `$$total / `$$BudgetCap (Remaining `$$remaining)" -ForegroundColor DarkGray
        return $true
    }
    catch {
        Write-Warning "[BUDGET] Failed to check budget: $($_.Exception.Message)"
        return $true # Fail open to avoid blocking ops on API error, or set to $false to fail closed
    }
}
