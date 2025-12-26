Write-Host "=== Jarvis-ShowQueueSummary ===" -ForegroundColor Cyan

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir  = Split-Path -Parent $scriptPath

# 1) Load env
$envLoader = Join-Path $scriptDir "Jarvis-LoadEnv.ps1"
if (-not (Test-Path $envLoader)) {
    Write-Host "ERROR: Jarvis-LoadEnv.ps1 not found at $envLoader" -ForegroundColor Red
    exit 1
}
. $envLoader
Write-Host "Loaded environment from Jarvis-LoadEnv.ps1." -ForegroundColor DarkGray

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Host "ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY missing." -ForegroundColor Red
    exit 1
}

# 2) Build commands URL (single string, like HealthSummary)
$baseUrl = $env:SUPABASE_URL.Trim().TrimEnd('/')

$limit = 50
$commandsUrl = "$baseUrl/rest/v1/az_commands" +
               "?select=id,agent,action,status,project,created_at,logs" +
               "&project=eq.AION-ZERO" +
               "&order=created_at.desc" +
               "&limit=$limit"

Write-Host "Commands URL: $commandsUrl" -ForegroundColor DarkGray

$headers = @{
    apikey         = $env:SUPABASE_SERVICE_ROLE_KEY
    Authorization  = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    Accept         = "application/json"
}

# 3) Fetch last 50 commands
Write-Host "Fetching last $limit commands for project=AION-ZERO..." -ForegroundColor DarkGray
try {
    $resp = Invoke-RestMethod -Method Get -Uri $commandsUrl -Headers $headers -ErrorAction Stop
}
catch {
    Write-Host "ERROR: Failed to fetch commands: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
        Write-Host "DETAILS: $($_.ErrorDetails.Message)" -ForegroundColor DarkRed
    }
    exit 1
}

if (-not $resp) {
    Write-Host "No commands found for AION-ZERO." -ForegroundColor Yellow
    exit 0
}

# 4) Summary by status
$byStatus = $resp | Group-Object status
Write-Host ""
Write-Host "=== Command Status Summary (last $limit) ===" -ForegroundColor Cyan
foreach ($g in $byStatus) {
    $label = if ($g.Name) { $g.Name } else { "<null>" }
    Write-Host ("{0,-12}: {1,3}" -f $label, $g.Count)
}
Write-Host "==========================================" -ForegroundColor Cyan

# 5) Summary by agent & status
$byAgent = $resp | Group-Object agent
Write-Host ""
Write-Host "=== Commands by Agent (last $limit) ===" -ForegroundColor Cyan
foreach ($agentGroup in $byAgent) {
    $agentName = if ($agentGroup.Name) { $agentGroup.Name } else { "<null>" }
    $inner = $agentGroup.Group | Group-Object status

    $line = "$agentName :"
    foreach ($st in $inner) {
        $sLabel = if ($st.Name) { $st.Name } else { "<null>" }
        $line += " $sLabel=$($st.Count)"
    }
    Write-Host $line
}
Write-Host "========================================" -ForegroundColor Cyan

# 6) List top 5 queued commands (if any)
$queued = $resp | Where-Object { $_.status -eq "queued" }

Write-Host ""
if (-not $queued) {
    Write-Host "No queued commands. 🎯" -ForegroundColor Green
}
else {
    $topQueued = $queued | Sort-Object created_at | Select-Object -First 5

    Write-Host "Top queued commands (oldest first):" -ForegroundColor Yellow
    foreach ($c in $topQueued) {
        $created = [datetime]$c.created_at
        $ageMin  = [math]::Round((New-TimeSpan -Start $created -End (Get-Date)).TotalMinutes, 1)
        Write-Host ("  #{0} [{1}] {2} (age={3} min)" -f $c.id, $c.agent, $c.action, $ageMin)
    }
}
