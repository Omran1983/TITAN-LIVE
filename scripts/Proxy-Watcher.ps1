# F:\AION-ZERO\scripts\Proxy-Watcher.ps1

$ErrorActionPreference = "Stop"

$targetsFile = "F:\AION-ZERO\env\proxy.targets"

if (-not (Test-Path $targetsFile)) {
    & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
        -Project "System" `
        -Agent "ProxyWatcher" `
        -Action "no-targets" `
        -Status "error" `
        -Details "proxy.targets file missing: $targetsFile"
    exit 1
}

$targets = Get-Content $targetsFile |
    Where-Object { $_ -and -not $_.TrimStart().StartsWith("#") } |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne "" }

if (-not $targets -or $targets.Count -eq 0) {
    & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
        -Project "System" `
        -Agent "ProxyWatcher" `
        -Action "no-targets" `
        -Status "warning" `
        -Details "No active targets in proxy.targets"
    exit 0
}

& "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
    -Project "System" `
    -Agent "ProxyWatcher" `
    -Action "run-start" `
    -Status "running" `
    -Details ("ProxyWatcher run for {0} target(s)" -f $targets.Count)

foreach ($t in $targets) {
    $label = $t
    if ($label -notmatch '^https?://') {
        $url = "https://$label"
    } else {
        $url = $label
    }

    try {
        $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15

        $code = $resp.StatusCode
        if ($code -ge 200 -and $code -lt 400) {
            & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
                -Project "System" `
                -Agent "ProxyWatcher" `
                -Action "check" `
                -Status "success" `
                -Details ("{0} OK (HTTP {1})" -f $label, $code)
        }
        else {
            & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
                -Project "System" `
                -Agent "ProxyWatcher" `
                -Action "check" `
                -Status "error" `
                -Details ("{0} bad status (HTTP {1})" -f $label, $code)
        }
    }
    catch {
        & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
            -Project "System" `
            -Agent "ProxyWatcher" `
            -Action "check" `
            -Status "error" `
            -Details ("{0} FAILED: {1}" -f $label, $_.Exception.Message)
    }
}

& "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
    -Project "System" `
    -Agent "ProxyWatcher" `
    -Action "run-done" `
    -Status "success" `
    -Details "ProxyWatcher run completed"
