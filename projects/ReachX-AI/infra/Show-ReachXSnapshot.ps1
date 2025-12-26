param(
    [int]$TopLeads = 10
)

$ErrorActionPreference = "Stop"

# ======================================================
# CONFIG — same key as Seed-ReachX / ReachX-HealthCheck
# ======================================================
$SupabaseUrl = "https://abkprecmhitqmmlzxfad.supabase.co"
$SupabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia3ByZWNtaGl0cW1tbHp4ZmFkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTk0NzY1OSwiZXhwIjoyMDc1NTIzNjU5fQ.-NrAHBNJOefsKpN_UIKhHNSukh7-ABO13IQjfNLswY4"

if (-not $SupabaseKey -or $SupabaseKey -like "<PASTE*") {
    Write-Host "ERROR: Please set `\$SupabaseKey` to your Supabase key." -ForegroundColor Red
    return
}

$headers = @{
    apikey        = $SupabaseKey
    Authorization = "Bearer $SupabaseKey"
}

function Invoke-ReachXGet {
    param(
        [Parameter(Mandatory = $true)][string]$Table,
        [string]$Query = "?select=*"
    )

    $uri = "$SupabaseUrl/rest/v1/$Table$Query"

    try {
        return Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    } catch {
        Write-Host "ERROR: Failed to call ${uri}: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

try {
    # --------------------------------------------
    # Fetch data
    # --------------------------------------------
    $clients   = Invoke-ReachXGet -Table "reachx_clients"   -Query "?select=id,name&limit=50"
    $campaigns = Invoke-ReachXGet -Table "reachx_campaigns" -Query "?select=id,name,client_id&limit=50"
    $leads     = Invoke-ReachXGet -Table "reachx_leads"     -Query "?select=id,company_name,score,status,campaign_id&limit=200"

    $clientCount   = if ($clients)   { $clients.Count }   else { 0 }
    $campaignCount = if ($campaigns) { $campaigns.Count } else { 0 }
    $leadCount     = if ($leads)     { $leads.Count }     else { 0 }

    # --------------------------------------------
    # Header
    # --------------------------------------------
    Write-Host ""
    Write-Host "=============================" -ForegroundColor DarkGray
    Write-Host " REACHX SNAPSHOT (Supabase) " -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor DarkGray
    Write-Host "Project  : abkprecmhitqmmlzxfad"
    Write-Host "Clients  : $clientCount"
    Write-Host "Campaigns: $campaignCount"
    Write-Host "Leads    : $leadCount"
    Write-Host ""

    # --------------------------------------------
    # Clients table
    # --------------------------------------------
    if ($clientCount -gt 0) {
        Write-Host "Clients" -ForegroundColor Yellow
        $clients |
            Select-Object `
                @{ Name = "Id";    Expression = { $_.id } },
                @{ Name = "Name";  Expression = { $_.name } } |
            Format-Table -AutoSize
        Write-Host ""
    } else {
        Write-Host "No clients found." -ForegroundColor DarkYellow
        Write-Host ""
    }

    # --------------------------------------------
    # Campaigns table
    # --------------------------------------------
    if ($campaignCount -gt 0) {
        Write-Host "Campaigns" -ForegroundColor Yellow
        $campaigns |
            Select-Object `
                @{ Name = "Id";       Expression = { $_.id } },
                @{ Name = "Name";     Expression = { $_.name } },
                @{ Name = "ClientId"; Expression = { $_.client_id } } |
            Format-Table -AutoSize
        Write-Host ""
    } else {
        Write-Host "No campaigns found." -ForegroundColor DarkYellow
        Write-Host ""
    }

    # --------------------------------------------
    # Leads breakdown: hot / warm / cold
    # --------------------------------------------
    if ($leadCount -gt 0) {
        $hot  = $leads | Where-Object { "$($_.score)".ToLower() -eq "hot" }
        $warm = $leads | Where-Object { "$($_.score)".ToLower() -eq "warm" }
        $cold = $leads | Where-Object { "$($_.score)".ToLower() -eq "cold" }

        Write-Host "Leads by score" -ForegroundColor Yellow
        Write-Host ("Hot  : {0}" -f ($hot.Count))  -ForegroundColor Green
        Write-Host ("Warm : {0}" -f ($warm.Count)) -ForegroundColor DarkYellow
        Write-Host ("Cold : {0}" -f ($cold.Count)) -ForegroundColor Gray
        Write-Host ""

        $top = $leads |
            Select-Object `
                @{ Name = "Company";  Expression = { $_.company_name } },
                @{ Name = "Score";    Expression = { $_.score } },
                @{ Name = "Status";   Expression = { $_.status } },
                @{ Name = "Campaign"; Expression = { $_.campaign_id } } `
            -First $TopLeads

        Write-Host "Top $TopLeads leads" -ForegroundColor Yellow
        $top | Format-Table -AutoSize
        Write-Host ""
    } else {
        Write-Host "No leads found." -ForegroundColor DarkYellow
        Write-Host ""
    }

    Write-Host "Snapshot complete." -ForegroundColor Cyan
}
catch {
    Write-Host "ERROR: Unhandled exception in Show-ReachXSnapshot: $($_.Exception.Message)" -ForegroundColor Red
    # no exit here; just show the error and return to the shell
}
