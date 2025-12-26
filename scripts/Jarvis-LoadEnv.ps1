param(
    [string]$EnvPath = "F:\AION-ZERO\.env"
)

if (-not (Test-Path $EnvPath)) {
    throw "Env file not found at $EnvPath"
}

$lines = Get-Content $EnvPath | Where-Object { $_ -and ($_ -notmatch "^\s*#") }

foreach ($line in $lines) {
    if ($line -notmatch "=") { continue }

    $parts = $line.Split("=", 2)
    $key = $parts[0].Trim()
    $value = $parts[1].Trim()

    if (-not $key) { continue }

    # Strip surrounding quotes if present
    if ($value -match '^"(.*)"$') {
        $value = $Matches[1]
    }

    # Export to process environment
    Set-Item -Path "Env:$key" -Value $value
}

Write-Host "Loaded environment variables from $EnvPath" -ForegroundColor Green

# --- CHECK FOR PANIC LOCK ---
$LockFile = "F:\AION-ZERO\JARVIS.PANIC.LOCK"
if (Test-Path $LockFile) {
    Write-Host ""
    Write-Host "!!! PANIC LOCK FOUND ($LockFile) !!!" -ForegroundColor Red
    Write-Host "System is in emergency stop mode. Exiting immediately." -ForegroundColor Red
    exit 1
}

