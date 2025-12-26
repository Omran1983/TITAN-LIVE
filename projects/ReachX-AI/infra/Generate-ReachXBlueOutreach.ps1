$ErrorActionPreference = "Stop"

$ExportsDir = "F:\ReachX-AI\exports"
$OutputRoot = "F:\ReachX-AI\outreach-employers"

function Get-SafeFileName {
    param([string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return "employer"
    }

    $invalid = [IO.Path]::GetInvalidFileNameChars() -join ''
    $pattern = "[{0}]" -f [Regex]::Escape($invalid)
    $safe = [Regex]::Replace($Name, $pattern, "")
    $safe = $safe.Trim()
    if ([string]::IsNullOrWhiteSpace($safe)) {
        return "employer"
    }

    $safe = $safe -replace "\s+", "-"
    return $safe
}

Write-Host ""
Write-Host "=========================================="
Write-Host " REACHX-BLUE — GENERATE OUTREACH DRAFTS  "
Write-Host "=========================================="

if (-not (Test-Path $ExportsDir)) {
    Write-Host ("ERROR: Exports directory not found: {0}" -f $ExportsDir)
    return
}

$latest = Get-ChildItem -Path $ExportsDir -Filter "reachx-employers-*.csv" |
          Sort-Object LastWriteTime -Descending |
          Select-Object -First 1

if (-not $latest) {
    Write-Host ("ERROR: No reachx-employers-*.csv files found in {0}" -f $ExportsDir)
    return
}

$CsvPath = $latest.FullName
Write-Host "Using employers CSV:"
Write-Host ("  {0}" -f $CsvPath)

if (-not (Test-Path $OutputRoot)) {
    New-Item -Path $OutputRoot -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$runDir    = Join-Path $OutputRoot "batch-$timestamp"

New-Item -Path $runDir -ItemType Directory -Force | Out-Null

Write-Host ""
Write-Host "Output folder:"
Write-Host ("  {0}" -f $runDir)
Write-Host ""

$employers = Import-Csv -Path $CsvPath

if (-not $employers -or $employers.Count -eq 0) {
    Write-Host "No rows in employers CSV. Nothing to generate."
    return
}

$draftCount = 0

foreach ($row in $employers) {
    $employerName = $row.employer_name
    $sector       = $row.sector
    $location     = $row.location
    $country      = $row.country
    $contactName  = $row.contact_name
    $contactRole  = $row.contact_role

    if (-not $employerName) {
        continue
    }

    $safeName = Get-SafeFileName -Name $employerName

    $locSlug = ""
    if ($location) {
        $locSlug = ($location -replace "\s+", "-")
    }

    if ($locSlug) {
        $baseName = "{0}-{1}" -f $safeName, $locSlug
    }
    else {
        $baseName = $safeName
    }

    $sectorText   = if ($sector)   { $sector }   else { "your operations" }
    $locationText = if ($location) { $location } else { "Mauritius" }
    $countryText  = if ($country)  { $country }  else { "Mauritius" }

    $contactGreeting = "Hi,"
    if ($contactName) {
        $contactGreeting = "Hi $contactName,"
    }

    $subjectLine     = "Support for $sectorText staffing at $employerName"
    $followupSubject = "Quick follow-up – blue-collar staffing for $employerName"

    # Email - initial
    $emailBody = @"
Subject: $subjectLine

$contactGreeting

My name is Omran from A-One Global Resourcing Ltd (Mauritius). We focus on supplying reliable blue-collar and frontline staff for employers in $locationText, especially in areas such as construction, retail, hospitality and logistics.

The main problems we see for companies like $employerName are:
- Time wasted reviewing unsuitable CVs.
- Last-minute shortages of staff when projects or shifts ramp up.
- Difficulty maintaining a stable pool of workers for recurring roles.

This is exactly where we can help:
- Building and maintaining a pool of workers for roles such as drivers, warehouse staff, helpers, machine operators, housekeeping staff and general labour.
- Doing the initial screening so you only see candidates who match your basic requirements.
- Aligning with your shift patterns and projects so you have a more predictable pipeline of staff.

I’d like to propose a very small, low-risk trial:
1) We agree on 1–2 roles where you have recurring demand.
2) We supply a shortlist of pre-screened candidates.
3) You evaluate us based on reliability, response time and fit.

Would you be open to a short call to see if this could support $employerName over the next few months?

Best regards,
Omran Ahmad
A-One Global Resourcing Ltd
Mauritius
Phone: +230 5788 7132
Email: deals@aogrl.com
"@

    # Email - follow up
    $followupBody = @"
Subject: $followupSubject

$contactGreeting

Just a quick follow-up on my previous email about supporting $employerName with blue-collar and frontline staffing in $locationText.

Even if you already have internal recruitment, we can add value by:
- Taking care of initial sourcing and screening for agreed roles.
- Providing a flexible pool of workers when you have peaks in demand.
- Reducing the time your team spends chasing candidates who do not show up or are not suitable.

If you are not the right person to discuss this at $employerName, I’d appreciate it if you could point me to the relevant contact.

Thanks in advance, and I look forward to hearing from you.

Best regards,
Omran Ahmad
A-One Global Resourcing Ltd
Mauritius
Phone: +230 5788 7132
Email: deals@aogrl.com
"@

    # WhatsApp
    $whatsAppBody = @"
Hi, this is Omran from A-One Global Resourcing Ltd in Mauritius.

We help employers like $employerName with blue-collar and frontline staffing in $locationText (drivers, warehouse staff, helpers, construction workers, hotel staff, etc.).

The idea is simple:
- We build and maintain a pool of workers for the roles you choose.
- We handle initial screening.
- You get a smaller, better shortlist when you need people.

If this could be useful for your operations, could you share the best contact to speak with about staffing, or a good time for a quick call?

Thanks,
Omran
+230 5788 7132
"@

    # LinkedIn DM
    $linkedInBody = @"
Hi,

I’m Omran, running A-One Global Resourcing Ltd in Mauritius. We support employers like $employerName with blue-collar and frontline staffing (drivers, warehouse, construction, retail and hospitality roles) in $locationText.

I’d like to connect and see if there’s scope to help you stabilise staffing for recurring roles and peak periods.

If you’re the right person to discuss staffing support, I’d be happy to share a concise overview and a small trial approach. Otherwise, I’d appreciate being pointed to the appropriate contact.

Best regards,
Omran
"@

    $emailFile     = Join-Path $runDir ($baseName + "-email.txt")
    $followupFile  = Join-Path $runDir ($baseName + "-followup.txt")
    $whatsAppFile  = Join-Path $runDir ($baseName + "-whatsapp.txt")
    $linkedInFile  = Join-Path $runDir ($baseName + "-linkedin.txt")

    Set-Content -Path $emailFile    -Value $emailBody    -Encoding UTF8
    Set-Content -Path $followupFile -Value $followupBody -Encoding UTF8
    Set-Content -Path $whatsAppFile -Value $whatsAppBody -Encoding UTF8
    Set-Content -Path $linkedInFile -Value $linkedInBody -Encoding UTF8

    $draftCount++
}

Write-Host ("Generated outreach drafts for {0} employer(s)." -f $draftCount)
Write-Host "Per employer you now have:"
Write-Host "  - *-email.txt"
Write-Host "  - *-followup.txt"
Write-Host "  - *-whatsapp.txt"
Write-Host "  - *-linkedin.txt"
Write-Host ""
Write-Host "You can review and customize them under:"
Write-Host ("  {0}" -f $runDir)
