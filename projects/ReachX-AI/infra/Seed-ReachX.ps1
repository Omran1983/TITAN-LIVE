param(
    [string]$SupabaseUrl = "https://abkprecmhitqmmlzxfad.supabase.co",   # e.g. https://abkprecmhitqmmlzxfad.supabase.co
    [string]$SupabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia3ByZWNtaGl0cW1tbHp4ZmFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk5NDc2NTksImV4cCI6MjA3NTUyMzY1OX0.laMBfcRG_liLwsaslI0qZyGJwrpgiryUmzy8k-rls2o"
)

if (-not $SupabaseUrl -or -not $SupabaseKey -or $SupabaseUrl -like "*YOUR_SUPABASE_URL*") {
    Write-Error "Please edit Seed-ReachX.ps1 and set Supabase URL and Key."
    exit 1
}

# ============================
# Headers & helper
# ============================
$headers = @{
    "apikey"        = $SupabaseKey
    "Authorization" = "Bearer $SupabaseKey"
    "Content-Type"  = "application/json"
    "Prefer"        = "return=representation"
}

function Invoke-ReachXRequest {
    param(
        [string]$Path,
        [string]$Method,
        [object]$Body = $null
    )

    $uri = "$SupabaseUrl/rest/v1/$Path"

    if ($Body -ne $null) {
        $json = $Body | ConvertTo-Json -Depth 10
        return Invoke-RestMethod -Uri $uri -Headers $headers -Method $Method -Body $json
    } else {
        return Invoke-RestMethod -Uri $uri -Headers $headers -Method $Method
    }
}

Write-Host "Using Supabase: $SupabaseUrl" -ForegroundColor Cyan

# ============================
# 1) Create demo client
# ============================
Write-Host "`n--- Creating demo client ---" -ForegroundColor Yellow

$clientBody = @{
    name          = "Demo Recruitment Agency"
    contact_email = "contact@demo-recruitment.test"
    phone         = "+2300000000"
    status        = "active"
}

$clientResult = Invoke-ReachXRequest -Path "reachx_clients" -Method "POST" -Body $clientBody
$clientId = $clientResult[0].id
Write-Host "Created client id: $clientId" -ForegroundColor Green

# ============================
# 2) Create demo campaign
# ============================
Write-Host "`n--- Creating demo campaign ---" -ForegroundColor Yellow

$campaignBody = @{
    client_id        = $clientId
    name             = "Gulf Hospitality Recruitment – Trial"
    target_industry  = "Hospitality"
    target_countries = @("UAE","Qatar","Saudi Arabia")
    languages        = @("en","fr","mfe","hi","ur")
    status           = "running"
}

$campaignResult = Invoke-ReachXRequest -Path "reachx_campaigns" -Method "POST" -Body $campaignBody
$campaignId = $campaignResult[0].id
Write-Host "Created campaign id: $campaignId" -ForegroundColor Green

# ============================
# 3) Create demo leads
# ============================
Write-Host "`n--- Creating demo leads ---" -ForegroundColor Yellow

$demoLeads = @(
    @{
        client_id    = $clientId
        campaign_id  = $campaignId
        company_name = "Desert Star Hotels Group"
        contact_name = "Amir Khan"
        role         = "HR Manager"
        email        = "amir.khan@desertstarhotels.test"
        phone        = "+971500000001"
        website      = "https://www.desertstarhotels.test"
        country      = "UAE"
        industry     = "Hospitality"
        language     = "en"
        score        = "hot"
        source       = "web"
        status       = "new"
    },
    @{
        client_id    = $clientId
        campaign_id  = $campaignId
        company_name = "Pearl Bay Resorts"
        contact_name = "Marie Dupont"
        role         = "Talent Acquisition Lead"
        email        = "marie.dupont@pearlbayresorts.test"
        phone        = "+974500000002"
        website      = "https://www.pearlbayresorts.test"
        country      = "Qatar"
        industry     = "Hospitality"
        language     = "fr"
        score        = "warm"
        source       = "web"
        status       = "new"
    },
    @{
        client_id    = $clientId
        campaign_id  = $campaignId
        company_name = "Red Dunes Luxury Stays"
        contact_name = "Sameer Ali"
        role         = "Recruitment Officer"
        email        = "sameer.ali@reddunesluxury.test"
        phone        = "+966500000003"
        website      = "https://www.reddunesluxury.test"
        country      = "Saudi Arabia"
        industry     = "Hospitality"
        language     = "en"
        score        = "cold"
        source       = "web"
        status       = "new"
    }
)

foreach ($lead in $demoLeads) {
    $leadResult = Invoke-ReachXRequest -Path "reachx_leads" -Method "POST" -Body $lead
    Write-Host "Created lead id: $($leadResult[0].id) for company: $($lead.company_name)" -ForegroundColor Green
}

# ============================
# 4) Fetch leads back as a sanity check
# ============================
Write-Host "`n--- Fetching leads back for sanity check ---" -ForegroundColor Yellow

# Filter: by campaign_id using querystring
$filterPath = "reachx_leads?campaign_id=eq.$campaignId&select=*"
$leadsFetched = Invoke-ReachXRequest -Path $filterPath -Method "GET"

Write-Host "Fetched $(( $leadsFetched | Measure-Object ).Count) leads for campaign $campaignId" -ForegroundColor Cyan

foreach ($lf in $leadsFetched) {
    Write-Host (" - {0} ({1}) score={2} status={3}" -f $lf.company_name, $lf.country, $lf.score, $lf.status)
}

Write-Host "`nSeeding completed." -ForegroundColor Green
