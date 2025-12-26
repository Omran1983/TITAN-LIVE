$ErrorActionPreference = "Stop"

function Get-ReachXEnv {
    $projectRoot = Split-Path $PSScriptRoot -Parent
    $envPath     = Join-Path $projectRoot ".env"

    if (!(Test-Path $envPath)) {
        throw "Missing .env at $envPath"
    }

    $envMap = @{}
    Get-Content $envPath | ForEach-Object {
        if (-not $_) { return }
        $line = $_.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { return }
        $parts = $line -split "=", 2
        if ($parts.Count -ne 2) { return }
        $key = $parts[0].Trim()
        $val = $parts[1].Trim()
        if ($key) { $envMap[$key] = $val }
    }

    if (-not $envMap.ContainsKey("REACHX_SUPABASE_URL")) {
        throw "REACHX_SUPABASE_URL missing in .env"
    }

    # Prefer service key for seeding; fallback to anon if missing
    $svcKey = $null
    if ($envMap.ContainsKey("REACHX_SUPABASE_SERVICE_KEY")) {
        $svcKey = $envMap["REACHX_SUPABASE_SERVICE_KEY"]
    } elseif ($envMap.ContainsKey("REACHX_SUPABASE_ANON_KEY")) {
        $svcKey = $envMap["REACHX_SUPABASE_ANON_KEY"]
    } else {
        throw "No Supabase key found (REACHX_SUPABASE_SERVICE_KEY or REACHX_SUPABASE_ANON_KEY)."
    }

    return [PSCustomObject]@{
        Url = $envMap["REACHX_SUPABASE_URL"]
        Key = $svcKey
    }
}

$cfg     = Get-ReachXEnv
$baseUrl = $cfg.Url.TrimEnd("/")

function Invoke-ReachXInsert {
    param(
        [Parameter(Mandatory=$true)][string]$Table,
        [Parameter(Mandatory=$true)][array]$Rows
    )

    if (-not $Rows -or $Rows.Count -eq 0) {
        return
    }

    $uri = "$baseUrl/rest/v1/$Table"

    $headers = @{
        apikey        = $cfg.Key
        Authorization = "Bearer $($cfg.Key)"
        "Content-Type" = "application/json"
        Prefer        = "return=minimal"
    }

    $body = $Rows | ConvertTo-Json -Depth 5

    Write-Host "Seeding $($Rows.Count) row(s) into $Table..." -ForegroundColor Cyan
    try {
        Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body | Out-Null
        Write-Host "OK: $Table" -ForegroundColor Green
    }
    catch {
        $detail = $_.ErrorDetails.Message
        if (-not $detail) { $detail = $_.Exception.Message }
        Write-Warning ("Failed seeding {0}: {1}" -f $Table, $detail)
    }
}

# -------- Seed Agents --------
$agentsRows = @(
    [pscustomobject]@{
        agency_name   = "Global Talent Nepal"
        country       = "Nepal"
        city          = "Kathmandu"
        routes        = "NP → MU"
        status        = "active"
        contact_name  = "Sanjay Thapa"
        contact_phone = "+977-981234567"
        whatsapp      = "+977-981234567"
        contact_email = "sanjay@globalnepal.com"
        notes         = "Construction and hospitality pipeline."
    },
    [pscustomobject]@{
        agency_name   = "Desert Link HR"
        country       = "United Arab Emirates"
        city          = "Dubai"
        routes        = "AE → MU"
        status        = "active"
        contact_name  = "Fatima Al-Najjar"
        contact_phone = "+971-50-1234567"
        whatsapp      = "+971-50-1234567"
        contact_email = "fatima@desertlinkhr.com"
        notes         = "Retail + logistics staff; good English levels."
    },
    [pscustomobject]@{
        agency_name   = "South Asia Manpower"
        country       = "India"
        city          = "Mumbai"
        routes        = "IN → MU"
        status        = "active"
        contact_name  = "Rahul Mehta"
        contact_phone = "+91-9876543210"
        whatsapp      = "+91-9876543210"
        contact_email = "rahul@southasiahr.com"
        notes         = "Quick turnaround for supermarket and driver roles."
    }
)

# -------- Seed Employers --------
$employersRows = @(
    [pscustomobject]@{
        company_name = "OceanView Resorts Mauritius"   # existing NOT NULL column
        name         = "OceanView Resorts Mauritius"
        country      = "Mauritius"
        city         = "Flic-en-Flac"
        industry     = "Hospitality"
        contact_name = "Aisha Ramdanee"
        phone        = "+230 5 123 4567"
        email        = "hr@oceanview.mu"
        notes        = "Needs housekeeping, F&B, and front-office staff seasonally."
    },
    [pscustomobject]@{
        company_name = "PortLouis Logistics Hub"
        name         = "PortLouis Logistics Hub"
        country      = "Mauritius"
        city         = "Port Louis"
        industry     = "Logistics"
        contact_name = "Jean-Marc Dupont"
        phone        = "+230 5 234 5678"
        email        = "jm.dupont@pl-logistics.mu"
        notes        = "Warehouse pickers, forklift operators, night shift."
    },
    [pscustomobject]@{
        company_name = "Island Fresh Supermarkets"
        name         = "Island Fresh Supermarkets"
        country      = "Mauritius"
        city         = "Curepipe"
        industry     = "Retail"
        contact_name = "Nadia Bhugun"
        phone        = "+230 5 345 6789"
        email        = "nadia.bhugun@islandfresh.mu"
        notes        = "Cashiers, shelf stackers, deli counter staff."
    }
)

# -------- Seed Dormitories --------
$dormsRows = @(
    [pscustomobject]@{
        name           = "Port Louis Worker Residence"
        location       = "Port Louis"
        capacity       = 80
        available_beds = 12
        manager_name   = "Mr. Kumar"
        phone          = "+230 5 111 2233"
        notes          = "Close to port and logistics area; shared kitchen; curfew 22:00."
    },
    [pscustomobject]@{
        name           = "Seaview Staff Lodge"
        location       = "Flic-en-Flac"
        capacity       = 40
        available_beds = 8
        manager_name   = "Mrs. Devi"
        phone          = "+230 5 444 5566"
        notes          = "Ideal for hospitality staff working on the west coast."
    },
    [pscustomobject]@{
        name           = "Central City Dorms"
        location       = "Curepipe"
        capacity       = 60
        available_beds = 15
        manager_name   = "Mr. Lee"
        phone          = "+230 5 777 8899"
        notes          = "Good bus connectivity; mixed nationalities."
    }
)

# -------- Seed Workers --------
$workersRows = @(
    [pscustomobject]@{
        full_name     = "Ramesh Kumar"
        country       = "Nepal"
        agent_name    = "Global Talent Nepal"
        employer_name = "PortLouis Logistics Hub"
        job_title     = "Warehouse Picker"
        primary_skill = "Warehouse Picker"
        status        = "available"
        phone         = "+230 5 900 1001"
        notes         = "1 year experience; English + Hindi."
    },
    [pscustomobject]@{
        full_name     = "Sita Devi"
        country       = "Nepal"
        agent_name    = "Global Talent Nepal"
        employer_name = "OceanView Resorts Mauritius"
        job_title     = "Housekeeper"
        primary_skill = "Housekeeping"
        status        = "deployed"
        phone         = "+230 5 900 1002"
        notes         = "Previous Gulf experience; good references."
    },
    [pscustomobject]@{
        full_name     = "Mohammed Ali"
        country       = "India"
        agent_name    = "South Asia Manpower"
        employer_name = "Island Fresh Supermarkets"
        job_title     = "Cashier"
        primary_skill = "Cashier"
        status        = "shortlisted"
        phone         = "+230 5 900 1003"
        notes         = "Fluent English and French; POS trained."
    },
    [pscustomobject]@{
        full_name     = "John Mathew"
        country       = "India"
        agent_name    = "South Asia Manpower"
        employer_name = "PortLouis Logistics Hub"
        job_title     = "Forklift Operator"
        primary_skill = "Forklift Operator"
        status        = "available"
        phone         = "+230 5 900 1004"
        notes         = "Forklift license; night shifts ok."
    },
    [pscustomobject]@{
        full_name     = "Ahmed Hassan"
        country       = "United Arab Emirates"
        agent_name    = "Desert Link HR"
        employer_name = "OceanView Resorts Mauritius"
        job_title     = "Waiter"
        primary_skill = "Waiter"
        status        = "deployed"
        phone         = "+230 5 900 1005"
        notes         = "Previous 5-star hotel experience."
    },
    [pscustomobject]@{
        full_name     = "Fatima Noor"
        country       = "United Arab Emirates"
        agent_name    = "Desert Link HR"
        employer_name = "Island Fresh Supermarkets"
        job_title     = "Deli Counter Staff"
        primary_skill = "Deli Counter Staff"
        status        = "shortlisted"
        phone         = "+230 5 900 1006"
        notes         = "Good customer service skills."
    }
)

Invoke-ReachXInsert -Table "agents"      -Rows $agentsRows
Invoke-ReachXInsert -Table "employers"   -Rows $employersRows
Invoke-ReachXInsert -Table "dormitories" -Rows $dormsRows
Invoke-ReachXInsert -Table "workers"     -Rows $workersRows

Write-Host "Seeding complete." -ForegroundColor Cyan
