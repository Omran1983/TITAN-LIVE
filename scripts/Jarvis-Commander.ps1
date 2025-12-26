# Jarvis-Commander.ps1
# -----------------------------------------------------------------------------
# THE COMMANDER LAYER (Phase 8) - COO
# -----------------------------------------------------------------------------
# High-Level Strategic Logic for the Autonomous Empire.
# "Looks at the big picture and tells the Lieutenants (Agents) what to focus on."
# -----------------------------------------------------------------------------

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\Jarvis-LoadEnv.ps1"

$url = $env:SUPABASE_URL
$key = $env:SUPABASE_SERVICE_ROLE_KEY
$headers = @{ apikey = $key; Authorization = "Bearer $key" }

function Write-Log { param($Msg) Write-Host "[COMMANDER] $Msg" -ForegroundColor Magenta }

# 1. GATHER INTELLIGENCE (SITREP)
Write-Log "Gathering SITREP..."

# A. Financials
# Mock: In prod, query az_ledger
$DailySpend = 0.45 
$Budget = 5.00
$MoneyRisk = ($DailySpend / $Budget) -gt 0.8 # Risk if > 80%

# B. Stability
# Check unresolved incidents
$Incidents = Invoke-RestMethod -Uri "$url/rest/v1/az_reflex_incidents?status=eq.investigating&select=count" -Method Head -Headers $headers -ResponseHeadersVariable 'RH'
$OpenIssues = 0
if ($RH["Content-Range"] -match "/(\d+)") { $OpenIssues = [int]$Matches[1] }

# C. Capability
# Check Graph Nodes
$Nodes = Invoke-RestMethod -Uri "$url/rest/v1/az_graph_sources?select=count" -Method Head -Headers $headers -ResponseHeadersVariable 'RHNG'
$Knowledge = 0
if ($RHNG["Content-Range"] -match "/(\d+)") { $Knowledge = [int]$Matches[1] }

Write-Log "SITREP: Spend=${DailySpend}/${Budget} | Issues=$OpenIssues | Knowledge=$Knowledge"

# 2. DECIDE STRATEGY (The "Generals" Logic)

$Mission = @{}

if ($OpenIssues -gt 5) {
    # DEFCON 3: STABILIZE
    $Mission.Title = "Operation: Stability"
    $Mission.Instruction = "Reflex Incidents are high ($OpenIssues). Focus ALL agents on clearing the incident backlog using the Reflex Doctor. Pause new features."
    $Mission.Type = "fix"
}
elseif ($MoneyRisk) {
    # DEFCON 4: AUSTERITY
    $Mission.Title = "Operation: Austerity"
    $Mission.Instruction = "Budget is low. Analyze 'az_ledger' and identify 3 high-cost tasks to deprecate or optimize. Pause non-essential scraping."
    $Mission.Type = "optimize"
}
elseif ($Knowledge -lt 50) {
    # DEFCON 5: RESEARCH
    $Mission.Title = "Operation: Brain Expansion"
    $Mission.Instruction = "Knowledge graph is thin ($Knowledge sources). Spider 10 new high-value technical blogs/docs related to 'Autonomous AI' and ingest them."
    $Mission.Type = "research"
}
else {
    # DEFCON 1: EXPANSION (Empire Mode)
    $Mission.Title = "Operation: Empire Growth"
    $Mission.Instruction = "System is Green. Select the most impactful feature for 'ReachX' from the roadmap (e.g., UX optimization or Candidate Matching) and implement it."
    $Mission.Type = "build"
}

# 3. ISSUE ORDERS (Commission)
Write-Log "STRATEGY SELECTED: $($Mission.Title)"

# Check if we already issued a command like this recently (Dedupe)
$today = (Get-Date).ToString("yyyy-MM-dd")
$chk = Invoke-RestMethod -Uri "$url/rest/v1/az_commands?instruction=ilike.*$($Mission.Title)*&created_at=gte.$today" -Headers $headers
if ($chk.Count -gt 0) {
    Write-Log "Order already issued for today. Standing by."
    exit
}

$body = @{
    project     = "AION-ZERO"
    instruction = "COMMANDER: $($Mission.Instruction)"
    status      = "queued"
    action      = $Mission.Type
    origin      = "commander_strategy"
} | ConvertTo-Json

Invoke-RestMethod -Method Post -Uri "$url/rest/v1/az_commands" -Headers $headers -Body $body -ContentType "application/json"

Write-Log "ORDERS ISSUED."
