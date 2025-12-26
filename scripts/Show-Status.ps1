# F:\AION-ZERO\scripts\Show-Status.ps1

$ErrorActionPreference = "Stop"

. "F:\AION-ZERO\scripts\Load-Supabase.ps1"

$uri = "$SBURL/rest/v1/proxy_events?select=project,agent,action,status,details,created_at&order=created_at.desc&limit=50"

$events = Invoke-RestMethod -Uri $uri -Headers $SBHeaders -Method Get

$events |
  Select-Object project, agent, action, status, created_at, details |
  Sort-Object created_at -Descending |
  Format-Table -AutoSize
