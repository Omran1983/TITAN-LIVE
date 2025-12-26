# F:\AION-ZERO\scripts\Verify-AZLock.ps1
$ErrorActionPreference = "Stop"

$lockPath = "F:\AION-ZERO\state\az.lock.json"

if (-not (Test-Path $lockPath)) {
    & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
        -Project "System" `
        -Agent "AZ-Lock" `
        -Action "verify" `
        -Status "error" `
        -Details "Lockfile missing: $lockPath"
    exit 1
}

$lock = Get-Content $lockPath -Raw | ConvertFrom-Json

$drift = @()
foreach ($entry in $lock.files) {
    $path = $entry.path
    $expected = $entry.hash

    if (-not (Test-Path $path)) {
        if ($expected) {
            $drift += "MISSING: $path (had hash $expected)"
        }
        continue
    }

    $current = (Get-FileHash -Path $path -Algorithm SHA256).Hash
    if ($expected -and $current -ne $expected) {
        $drift += "CHANGED: $path"
    }
    elseif (-not $expected) {
        $drift += "NOW_EXISTS: $path"
    }
}

if ($drift.Count -eq 0) {
    & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
        -Project "System" `
        -Agent "AZ-Lock" `
        -Action "verify" `
        -Status "success" `
        -Details "Lock OK – no drift"
}
else {
    $msg = $drift -join "; "
    & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
        -Project "System" `
        -Agent "AZ-Lock" `
        -Action "verify" `
        -Status "warning" `
        -Details "Drift detected: $msg"
}
