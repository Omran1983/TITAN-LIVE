param(
    [switch]$IncludeWarm,
    [switch]$IncludeCold,
    [int]$Top = 20
)

$ErrorActionPreference = "Stop"

# ======================================================
# CONFIG — same as ReachX-HealthCheck
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
        Write-Host "ERROR calling ${uri} - $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

try {
    Write-Host ""
    Write-Host "===============================" -ForegroundColor DarkGray
    Write-Host " REACHX — PRIORITY LEADS VIEW " -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor DarkGray

    $leads = Invoke-ReachXGet -Table "reachx_leads" -Query "?select=id,company_name,score,status,campaign_id&limit=200"

    if (-not $leads -or $leads.Count -eq 0) {
        Write-Host "No leads found in reachx_leads." -ForegroundColor DarkYellow
        return
    }

    # Normalise score
    $hot  = $leads | Where-Object { "$($_.score)".ToLower() -eq "hot" }
    $warm = $leads | Where-Object { "$($_.score)".ToLower() -eq "warm" }
    $cold = $leads | Where-Object { "$($_.score)".ToLower() -eq "cold" }

    Write-Host ("Hot  leads : {0}" -f ($hot.Count))  -ForegroundColor Green
    Write-Host ("Warm leads : {0}" -f ($warm.Count)) -ForegroundColor DarkYellow
    Write-Host ("Cold leads : {0}" -f ($cold.Count)) -ForegroundColor Gray
    Write-Host ""

    # Decide what to show
    $listToShow = @()

    if ($hot.Count -gt 0) {
        $listToShow += $hot
    }
    if ($IncludeWarm -and $warm.Count -gt 0) {
        $listToShow += $warm
    }
    if ($IncludeCold -and $cold.Count -gt 0) {
        $listToShow += $cold
    }

    if ($listToShow.Count -eq 0) {
        Write-Host "Showing HOT only (default)." -ForegroundColor DarkGray
        $listToShow = $hot
    }

    $listToShow = $listToShow | Select-Object `
        @{ Name = "Company";  Expression = { $_.company_name } },
        @{ Name = "Score";    Expression = { $_.score } },
        @{ Name = "Status";   Expression = { $_.status } },
        @{ Name = "Campaign"; Expression = { $_.campaign_id } } `
        -First $Top

    if ($listToShow.Count -eq 0) {
        Write-Host "No leads matched the filter." -ForegroundColor DarkYellow
        return
    }

    Write-Host ("Top {0} priority leads" -f $listToShow.Count) -ForegroundColor Yellow
    $listToShow | Format-Table -AutoSize

    Write-Host ""
    Write-Host "Hint: add -IncludeWarm and/or -IncludeCold if you want a full pipeline." -ForegroundColor DarkGray
}
catch {
    Write-Host "ERROR: Unhandled exception in Show-ReachXHotLeads: $($_.Exception.Message)" -ForegroundColor Red
}
