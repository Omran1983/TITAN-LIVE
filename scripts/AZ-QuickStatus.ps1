# F:\AION-ZERO\scripts\AZ-QuickStatus.ps1

$ErrorActionPreference = "Stop"

. "F:\AION-ZERO\scripts\Load-Supabase.ps1"

Write-Host "=== AZ Quick Status ===" -ForegroundColor Cyan
Write-Host "SBURL: $SBURL"

# Pending commands
$pendingUri = "$SBURL/rest/v1/az_commands" +
              "?select=id,command,project,target_agent,status,created_at,completed_at,error" +
              "&order=id.asc" +
              "&limit=20"

$pending = Invoke-RestMethod -Uri $pendingUri -Headers $SBHeaders -Method Get

Write-Host "`nPending commands:" -ForegroundColor Yellow
if (-not $pending -or $pending.Count -eq 0) {
    Write-Host "  None"
} else {
    $pending | Format-Table
}

# AZ-Command events
$eventsUri = "$SBURL/rest/v1/proxy_events" +
             "?select=project,agent,action,status,details,created_at" +
             "&order=created_at.desc" +
             "&limit=40"

$events = Invoke-RestMethod -Uri $eventsUri -Headers $SBHeaders -Method Get

Write-Host "`nLast 5 AZ-Command events:" -ForegroundColor Yellow
$events |
  Sort-Object created_at |
  Where-Object { $_.agent -eq 'AZ-Command' } |
  Select-Object -Last 5 | Format-List

Write-Host "`nWrapper log tail:" -ForegroundColor Yellow
Get-Content "F:\AION-ZERO\logs\AZ-CommandPoller-wrapper.log" -Tail 10
