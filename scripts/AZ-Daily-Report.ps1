$ErrorActionPreference = "Stop"

$root    = "F:\AION-ZERO"
$logDir  = Join-Path $root "logs"

. "F:\AION-ZERO\scripts\Send-AOGRLMail.ps1"

function Get-LogTail {
    param(
        [string]$Path,
        [int]$Lines = 30
    )

    if (-not (Test-Path $Path)) {
        return "(No log found at $Path)"
    }

    (Get-Content $Path -Tail $Lines) -join "`n"
}

$nightBuildPath = Join-Path $logDir "AZ-build-journal.md"
$okasinaPath    = Join-Path $logDir "okasina-build-journal.md"
$eduPath        = Join-Path $logDir "educonnect-build-journal.md"
$eduStatusPath  = Join-Path $logDir "educonnect-status-history.md"

$nightTail = Get-LogTail -Path $nightBuildPath -Lines 30
$okaTail   = Get-LogTail -Path $okasinaPath    -Lines 30
$eduTail   = Get-LogTail -Path $eduPath        -Lines 30
$eduStatus = Get-LogTail -Path $eduStatusPath  -Lines 30

$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$body = @"
<h2>AZ Daily Progress Report</h2>
<p><b>Time:</b> $now</p>

<h3>Night Build (AION-ZERO / EduConnect / OKASINA)</h3>
<pre style="background:#020617;color:#e5e7eb;padding:10px;border-radius:6px;font-size:12px;">$nightTail</pre>

<h3>OKASINA Builds</h3>
<pre style="background:#020617;color:#e5e7eb;padding:10px;border-radius:6px;font-size:12px;">$okaTail</pre>

<h3>EduConnect Builds</h3>
<pre style="background:#020617;color:#e5e7eb;padding:10px;border-radius:6px;font-size:12px;">$eduTail</pre>

<h3>EduConnect Live Status (last checks)</h3>
<pre style="background:#020617;color:#e5e7eb;padding:10px;border-radius:6px;font-size:12px;">$eduStatus</pre>
"@

Send-AOGRLMail `
    -To "omranahmad@yahoo.com" `
    -Subject "[AZ] Daily Progress Report" `
    -Body $body `
    -IsHtml

Write-Host "AZ Daily Progress Report email sent (with EduConnect status)." -ForegroundColor Green
