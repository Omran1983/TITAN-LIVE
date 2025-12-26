param(
    [switch]$IncludeWarm,
    [switch]$IncludeCold,
    [int]$Top = 200,
    [string]$OutputDir = "F:\ReachX-AI\exports"
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
    Write-Host "====================================" -ForegroundColor DarkGray
    Write-Host " REACHX — EXPORT PRIORITY LEADS CSV " -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor DarkGray

    # Ensure output directory exists
    if (-not (Test-Path $OutputDir)) {
        Write-Host "Creating output directory $OutputDir"
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }

    $leads = Invoke-ReachXGet -Table "reachx_leads" -Query "?select=id,company_name,score,status,campaign_id&limit=500"

    if (-not $leads -or $leads.Count -eq 0) {
        Write-Host "No leads found in reachx_leads. Nothing to export." -ForegroundColor DarkYellow
        return
    }

    # Normalise by score
    $hot  = $leads | Where-Object { "$($_.score)".ToLower() -eq "hot" }
    $warm = $leads | Where-Object { "$($_.score)".ToLower() -eq "warm" }
    $cold = $leads | Where-Object { "$($_.score)".ToLower() -eq "cold" }

    Write-Host ("Hot  leads : {0}" -f ($hot.Count))  -ForegroundColor Green
    Write-Host ("Warm leads : {0}" -f ($warm.Count)) -ForegroundColor DarkYellow
    Write-Host ("Cold leads : {0}" -f ($cold.Count)) -ForegroundColor Gray
    Write-Host ""

    # Build list to export
    $exportList = @()

    if ($hot.Count -gt 0) {
        $exportList += $hot
    }
    if ($IncludeWarm -and $warm.Count -gt 0) {
        $exportList += $warm
    }
    if ($IncludeCold -and $cold.Count -gt 0) {
        $exportList += $cold
    }

    if ($exportList.Count -eq 0) {
        # Default to hot only if no switches matched
        $exportList = $hot
        Write-Host "No filter switches provided or no matches; exporting HOT leads only." -ForegroundColor DarkGray
    }

    if ($exportList.Count -eq 0) {
        Write-Host "Nothing to export after filtering." -ForegroundColor DarkYellow
        return
    }

    # Limit
    $exportList = $exportList | Select-Object -First $Top

    # Shape export objects
    $rows = $exportList | ForEach-Object {
        [PSCustomObject]@{
            company_name = $_.company_name
            score        = $_.score
            status       = $_.status
            campaign_id  = $_.campaign_id
            # Room to extend later: segment, tags, notes, etc.
        }
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $fileName  = "reachx-leads-$timestamp.csv"
    $filePath  = Join-Path $OutputDir $fileName

    $rows | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8

    Write-Host ("Exported {0} leads to:" -f $rows.Count) -ForegroundColor Green
    Write-Host "  $filePath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "You can open this CSV in Excel, Sheets, Notion, or feed it into another script." -ForegroundColor DarkGray
}
catch {
    Write-Host "ERROR: Unhandled exception in Export-ReachXLeads: $($_.Exception.Message)" -ForegroundColor Red
}
