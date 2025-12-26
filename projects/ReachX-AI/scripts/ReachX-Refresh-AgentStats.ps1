param()

# This script just copies the refresh SQL to your clipboard
# so you can paste it into Supabase SQL editor and run it there.

$sql = @"
select reachx_refresh_agent_counters();

select id, name, full_name, country, city,
       leads_generated, workers_placed, status
from reachx_agents
order by country, full_name;

select * from reachx_dashboard_kpis;
"@

# Copy to clipboard (Windows)
if (Get-Command Set-Clipboard -ErrorAction SilentlyContinue) {
    $sql | Set-Clipboard
    Write-Host "✅ SQL copied to clipboard."
    Write-Host "➡ Paste into Supabase Studio → SQL and run."
} else {
    Write-Host "Set-Clipboard not available. Here is the SQL:"
    Write-Host "-----------------------------------------------"
    Write-Host $sql
    Write-Host "-----------------------------------------------"
}
