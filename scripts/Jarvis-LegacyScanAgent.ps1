param(
    [string]$ScanRoot = "F:\",
    [string]$ToolsDir = "F:\AION-ZERO\tools",
    [string]$LogsDir  = "F:\AION-ZERO\logs"
)

# Make failures explicit
$ErrorActionPreference = "Stop"

# Where is Python?
# If you ever need a specific path, change this to 'C:\Python313\python.exe' etc.
$pythonExe   = "python"
$scannerName = "python_legacy_scanner.py"
$scannerPath = Join-Path $ToolsDir $scannerName

# Ensure logs directory exists
if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile   = Join-Path $LogsDir ("legacy-scan-{0}.log" -f $timestamp)

# Basic sanity checks
if (-not (Test-Path $scannerPath)) {
    $msg = "Scanner script not found: $scannerPath"
    Write-Error $msg
    $msg | Out-File -FilePath $logFile -Encoding UTF8
    exit 1
}

if (-not (Test-Path $ScanRoot)) {
    $msg = "Scan root does not exist: $ScanRoot"
    Write-Error $msg
    $msg | Out-File -FilePath $logFile -Encoding UTF8
    exit 1
}

# Log header
"[{0}] Jarvis-LegacyScanAgent starting" -f (Get-Date -Format o) |
    Tee-Object -FilePath $logFile -Append | Out-Host
"  ScanRoot = $ScanRoot" |
    Tee-Object -FilePath $logFile -Append | Out-Host
"  ToolsDir = $ToolsDir" |
    Tee-Object -FilePath $logFile -Append | Out-Host
"  Scanner  = $scannerPath" |
    Tee-Object -FilePath $logFile -Append | Out-Host

# Build Python arguments (NO manual quoting – let .NET handle it)
$reportDir = $ToolsDir

# We'll use ArgumentList instead of a raw string to avoid the F:\\" problem.
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName               = $pythonExe
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.UseShellExecute        = $false
$psi.CreateNoWindow         = $true

# Add each argument as a separate token
$null = $psi.ArgumentList.Add($scannerPath)
$null = $psi.ArgumentList.Add("--root")
$null = $psi.ArgumentList.Add($ScanRoot)
$null = $psi.ArgumentList.Add("--report-dir")
$null = $psi.ArgumentList.Add($reportDir)

# For logging, show the full command line
$invocationDisplay = "{0} {1}" -f $psi.FileName, ($psi.ArgumentList -join " ")
"[{0}] Invoking: {1}" -f (Get-Date -Format o), $invocationDisplay |
    Tee-Object -FilePath $logFile -Append | Out-Host

$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $psi

$null = $proc.Start()

# Capture output
$stdout = $proc.StandardOutput.ReadToEnd()
$stderr = $proc.StandardError.ReadToEnd()

$proc.WaitForExit()
$exitCode = $proc.ExitCode

# Log stdout
if ($stdout) {
    "[{0}] --- Python STDOUT ---" -f (Get-Date -Format o) |
        Tee-Object -FilePath $logFile -Append | Out-Host
    $stdout |
        Tee-Object -FilePath $logFile -Append | Out-Host
}

# Log stderr (if any)
if ($stderr) {
    "[{0}] --- Python STDERR ---" -f (Get-Date -Format o) |
        Tee-Object -FilePath $logFile -Append | Out-Host
    $stderr |
        Tee-Object -FilePath $logFile -Append | Out-Host
}

# Try to extract the suspicious file count from stdout:
# Looks for: "Scan complete. 13 suspicious file(s) found."
[int]$hits = 0
if ($stdout -match "Scan complete\. (\d+) suspicious file\(s\) found\.") {
    $hits = [int]$matches[1]
}

"[{0}] Python exit code: {1}" -f (Get-Date -Format o), $exitCode |
    Tee-Object -FilePath $logFile -Append | Out-Host
"[{0}] Suspicious files reported: {1}" -f (Get-Date -Format o), $hits |
    Tee-Object -FilePath $logFile -Append | Out-Host

"[{0}] Jarvis-LegacyScanAgent finished" -f (Get-Date -Format o) |
    Tee-Object -FilePath $logFile -Append | Out-Host

# Later, we can use $hits to decide whether to send alerts / push to Supabase.
# For now, we just exit with the same code as Python.
exit $exitCode
