param(
    [string]$ExportsDir = "F:\ReachX-AI\exports",
    [string]$OutputRoot = "F:\ReachX-AI\outreach",
    [string]$CsvPath
)

$ErrorActionPreference = "Stop"

function Get-SafeFileName {
    param([string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return "company"
    }

    $invalid = [IO.Path]::GetInvalidFileNameChars() -join ''
    $pattern = "[{0}]" -f [Regex]::Escape($invalid)
    $safe = [Regex]::Replace($Name, $pattern, "")
    $safe = $safe.Trim()
    if ([string]::IsNullOrWhiteSpace($safe)) {
        return "company"
    }

    # Replace spaces with dashes
    $safe = $safe -replace "\s+", "-"
    return $safe
}

Write-Host ""
Write-Host "==================================" 
Write-Host " REACHX — GENERATE OUTREACH DRAFTS" 
Write-Host "==================================" 

# -------------------------------
# Resolve CSV path
# -------------------------------
if (-not $CsvPath) {
    if (-not (Test-Path $ExportsDir)) {
        Write-Host ("ERROR: Exports directory not found: {0}" -f $ExportsDir)
        return
    }

    $latest = Get-ChildItem -Path $ExportsDir -Filter "reachx-leads-*.csv" |
              Sort-Object LastWriteTime -Descending |
              Select-Object -First 1

    if (-not $latest) {
        Write-Host ("ERROR: No reachx-leads-*.csv files found in {0}" -f $ExportsDir)
        return
    }

    $CsvPath = $latest.FullName
    Write-Host "Using latest CSV:"
    Write-Host ("  {0}" -f $CsvPath)
}
else {
    if (-not (Test-Path $CsvPath)) {
        Write-Host ("ERROR: CSV file not found: {0}" -f $CsvPath)
        return
    }
    Write-Host "Using CSV:"
    Write-Host ("  {0}" -f $CsvPath)
}

# -------------------------------
# Prepare output directory
# -------------------------------
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

# -------------------------------
# Load leads from CSV
# -------------------------------
$leads = Import-Csv -Path $CsvPath

if (-not $leads -or $leads.Count -eq 0) {
    Write-Host "No rows found in CSV. Nothing to generate."
    return
}

$draftCount = 0

foreach ($lead in $leads) {
    $company    = $lead.company_name
    $score      = $lead.score
    $status     = $lead.status
    $campaignId = $lead.campaign_id

    $safeName = Get-SafeFileName -Name $company

    $campaignShort = ""
    if ($campaignId -and $campaignId.Length -ge 8) {
        $campaignShort = $campaignId.Substring(0, 8)
    }

    if ($campaignShort) {
        $baseName = "{0}-{1}" -f $safeName, $campaignShort
    }
    else {
        $baseName = $safeName
    }

    $scoreLower = ("{0}" -f $score).ToLower()

    $scoreLine = switch ($scoreLower) {
        "hot"  { "I’d like to position this as a high-priority channel for your current hiring." }
        "warm" { "I believe this could become a strong additional channel for your upcoming roles." }
        "cold" { "This is an introductory note to see if there’s a fit for future hiring cycles." }
        default { "I’d like to explore whether there’s a fit for your hiring roadmap." }
    }

    $subjectLine       = "Strategic recruitment support for $company"
    $followupSubject   = "Quick follow-up – recruitment support for $company"

    # ---------------------------
    # Email – initial outreach
    # ---------------------------
    $emailBody = @"
Subject: $subjectLine

Hi Hiring Team at $company,

My name is Omran from A-One Global Resourcing Ltd (Mauritius). We specialise in connecting qualified talent with Gulf-region hospitality brands similar to yours.

$scoreLine

What we can bring to your organisation:
- Pre-screened candidates for hotel and resort roles (front office, F&B, housekeeping, and support).
- Structured shortlists so your team reviews fewer CVs but higher-quality profiles.
- Coordinated communication to keep both your HR team and candidates aligned.

If you are open to it, I’d like to:
1) Understand your current and upcoming hiring needs for the next 3–6 months.
2) Share how we can plug into your process with minimal friction.
3) Propose a small initial trial so you can evaluate us on results, not promises.

Would you be available for a short call in the coming days to discuss this?

Best regards,
Omran Ahmad
A-One Global Resourcing Ltd
Mauritius
Phone: +230 5788 7132
Email: deals@aogrl.com
"@

    # ---------------------------
    # Email – follow-up
    # ---------------------------
    $followupBody = @"
Subject: $followupSubject

Hi,

Just a quick follow-up on my previous email about supporting $company with Gulf-region hospitality recruitment.

I know your team is busy, so I’d be happy to keep this simple:
- Share a concise overview of how we work.
- Align on 1–2 priority roles where we could add value.
- Run a small trial so you can judge us purely on candidate quality and speed.

If you are not the right contact for recruitment partnerships at $company, I’d appreciate it if you could point me to the right person.

Thanks in advance, and I look forward to hearing from you.

Best regards,
Omran Ahmad
A-One Global Resourcing Ltd
Mauritius
Phone: +230 5788 7132
Email: deals@aogrl.com
"@

    # ---------------------------
    # WhatsApp script
    # ---------------------------
    $whatsAppBody = @"
Hi, this is Omran from A-One Global Resourcing Ltd in Mauritius.

We specialise in Gulf-region hospitality recruitment and I’d like to explore if we can support $company with upcoming roles.

Key points:
- Pre-screened candidates for hotel and resort positions.
- Shortlists instead of large CV dumps.
- Clear communication and coordination with your HR team.

If this sounds relevant, could you please share the best contact for recruitment or a good time for a short call?

Thanks,
Omran
+230 5788 7132
"@

    # ---------------------------
    # LinkedIn DM script
    # ---------------------------
    $linkedInBody = @"
Hi,

I’m Omran, running A-One Global Resourcing Ltd in Mauritius. We support Gulf hotels and resorts with recruitment by providing pre-screened candidates and focused shortlists.

I’d like to connect and see if there’s scope to help $company with hiring over the next few months.

If you’re the right person for recruitment partnerships, I’d be glad to share a short overview and some options. Otherwise, I’d appreciate being pointed to the appropriate contact.

Best regards,
Omran
"@

    # ---------------------------
    # Write all draft files
    # ---------------------------
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

Write-Host ("Generated outreach drafts for {0} lead(s)." -f $draftCount)
Write-Host "Per lead you now have:"
Write-Host "  - *-email.txt"
Write-Host "  - *-followup.txt"
Write-Host "  - *-whatsapp.txt"
Write-Host "  - *-linkedin.txt"
Write-Host ""
Write-Host "You can review and customize them under:"
Write-Host ("  {0}" -f $runDir)
