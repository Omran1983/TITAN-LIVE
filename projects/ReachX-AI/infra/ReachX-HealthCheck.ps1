param(
    [string]$LogPath = "F:\Jarvis\logs\reachx-healthcheck.log"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ssZ")
    $line = "$timestamp | ReachX-HealthCheck | $Level | $Message"
    Write-Host $line
    if ($LogPath) {
        try {
            $dir = Split-Path -Path $LogPath -Parent
            if (-not (Test-Path $dir)) {
                New-Item -Path $dir -ItemType Directory -Force | Out-Null
            }
            Add-Content -Path $LogPath -Value $line
        } catch {
            # Use ${LogPath} so the ':' is treated as text, not part of the var name
            Write-Host "WARN: Failed to write to log file ${LogPath}: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

function Invoke-ReachXGet {
    param(
        [Parameter(Mandatory = $true)][string]$Table,
        [string]$Query = "?select=*"
    )

    if (-not $script:SupabaseUrl -or -not $script:SupabaseKey) {
        throw "Supabase URL or key not set"
    }

    $uri = "$($script:SupabaseUrl)/rest/v1/$Table$Query"

    $headers = @{
        apikey        = $script:SupabaseKey
        Authorization = "Bearer $($script:SupabaseKey)"
    }

    try {
        return Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    } catch {
        # Use ${uri} so the ':' parses correctly
        Write-Log "Error calling ${uri}: $($_.Exception.Message)" "ERROR"
        throw
    }
}

try {
    # Use the same URL + key as Seed-ReachX.ps1 (known working)
    $script:SupabaseUrl = "https://abkprecmhitqmmlzxfad.supabase.co"
    $script:SupabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia3ByZWNtaGl0cW1tbHp4ZmFkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTk0NzY1OSwiZXhwIjoyMDc1NTIzNjU5fQ.-NrAHBNJOefsKpN_UIKhHNSukh7-ABO13IQjfNLswY4"

    if (-not $script:SupabaseUrl -or -not $script:SupabaseKey) {
        Write-Log "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars not set" "ERROR"
        exit 1
    }

    Write-Log "ReachX health check started for $script:SupabaseUrl"

    $ok = $true

    # Basic counts
    $clients   = Invoke-ReachXGet -Table "reachx_clients"   -Query "?select=id,name&limit=10"
    $campaigns = Invoke-ReachXGet -Table "reachx_campaigns" -Query "?select=id,client_id,name&limit=10"
    $leads     = Invoke-ReachXGet -Table "reachx_leads"     -Query "?select=id,campaign_id,company_name,score,status&limit=10"

    $clientCount   = if ($clients) { $clients.Count } else { 0 }
    $campaignCount = if ($campaigns) { $campaigns.Count } else { 0 }
    $leadCount     = if ($leads) { $leads.Count } else { 0 }

    Write-Log "Counts — Clients: $clientCount, Campaigns: $campaignCount, Leads: $leadCount"

    if ($clientCount -lt 1) {
        Write-Log "No clients found in reachx_clients" "ERROR"
        $ok = $false
    }
    if ($campaignCount -lt 1) {
        Write-Log "No campaigns found in reachx_campaigns" "ERROR"
        $ok = $false
    }
    if ($leadCount -lt 1) {
        Write-Log "No leads found in reachx_leads" "ERROR"
        $ok = $false
    }

    # Relationship sanity check: first campaign should have at least one lead
    if ($campaignCount -ge 1) {
        $firstCampaign = $campaigns[0]
        $cid = $firstCampaign.id
        $campaignLeads = Invoke-ReachXGet -Table "reachx_leads" -Query "?select=id,company_name,score,status&campaign_id=eq.$cid"

        $campaignLeadCount = if ($campaignLeads) { $campaignLeads.Count } else { 0 }
        Write-Log "Campaign $cid has $campaignLeadCount leads"

        if ($campaignLeadCount -lt 1) {
            Write-Log "No leads linked to campaign $cid" "ERROR"
            $ok = $false
        } else {
            $sample = $campaignLeads | Select-Object -First 3
            foreach ($lead in $sample) {
                Write-Log "Lead: $($lead.company_name) score=$($lead.score) status=$($lead.status)"
            }
        }
    }

    if ($ok) {
        Write-Log "ReachX health check OK" "OK"
        exit 0
    } else {
        Write-Log "ReachX health check FAILED" "ERROR"
        exit 2
    }
} catch {
    Write-Log "Unhandled exception in ReachX-HealthCheck: $($_.Exception.Message)" "ERROR"
    exit 3
}
