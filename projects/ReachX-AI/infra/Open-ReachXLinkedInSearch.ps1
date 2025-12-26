param(
    [int]$MaxCompanies = 10,
    [string]$ExportsDir = "F:\ReachX-AI\exports"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "======================================"
Write-Host " REACHX — OPEN LINKEDIN SEARCH TABS  "
Write-Host "======================================"
Write-Host ""

if (-not (Test-Path $ExportsDir)) {
    Write-Host ("ERROR: Exports directory not found: {0}" -f $ExportsDir)
    return
}

# Get latest reachx-leads CSV
$latest = Get-ChildItem -Path $ExportsDir -Filter "reachx-leads-*.csv" |
          Sort-Object LastWriteTime -Descending |
          Select-Object -First 1

if (-not $latest) {
    Write-Host ("ERROR: No reachx-leads-*.csv files found in {0}" -f $ExportsDir)
    return
}

$csvPath = $latest.FullName
Write-Host "Using latest CSV:"
Write-Host ("  {0}" -f $csvPath)
Write-Host ""

$leads = Import-Csv -Path $csvPath

if (-not $leads -or $leads.Count -eq 0) {
    Write-Host "No rows found in CSV. Nothing to open."
    return
}

# Get unique company names
$companies = $leads |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_.company_name) } |
    Select-Object -ExpandProperty company_name -Unique

if ($companies.Count -eq 0) {
    Write-Host "No company_name values found in CSV."
    return
}

# Limit number of companies if needed
if ($MaxCompanies -gt 0 -and $companies.Count -gt $MaxCompanies) {
    $companies = $companies | Select-Object -First $MaxCompanies
}

Write-Host ("Opening LinkedIn people search for {0} compan(ies):" -f $companies.Count)
Write-Host ""

foreach ($company in $companies) {
    $query = "{0} HR" -f $company
    $encoded = [uri]::EscapeDataString($query)
    $url = "https://www.linkedin.com/search/results/people/?keywords=$encoded"

    Write-Host ("  {0}" -f $company)
    Write-Host ("    -> {0}" -f $url)

    # Open in default browser
    Start-Process $url
}

Write-Host ""
Write-Host "Done. Check your browser tabs and use the *-linkedin.txt drafts for each company."
