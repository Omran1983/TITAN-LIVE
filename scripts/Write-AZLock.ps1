# F:\AION-ZERO\scripts\Write-AZLock.ps1
$ErrorActionPreference = "Stop"

$lockPath = "F:\AION-ZERO\state\az.lock.json"

$files = @(
    "F:\AION-ZERO\env\supabase.secrets",
    "F:\AION-ZERO\env\cloudflare.secrets",
    "F:\AION-ZERO\env\proxy.targets",
    "F:\AION-ZERO\scripts\Load-Supabase.ps1",
    "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1",
    "F:\AION-ZERO\scripts\Ping-Infra.ps1",
    "F:\AION-ZERO\scripts\Jarvis-Watcher-Wrapper.ps1",
    "F:\AION-ZERO\scripts\Start-AZ-Wrapper.ps1",
    "F:\AION-ZERO\scripts\Invoke-AZHealth-Wrapper.ps1",
    "F:\AION-ZERO\scripts\Proxy-Watcher.ps1",
    "F:\AION-ZERO\scripts\AZ-Guard.ps1",
    "F:\AION-ZERO\scripts\Show-Status.ps1",
    "F:\AION-ZERO\scripts\Show-AgentSummary.ps1"
)

$result = [System.Collections.Generic.List[object]]::new()

foreach ($path in $files) {
    if (Test-Path $path) {
        $h = Get-FileHash -Path $path -Algorithm SHA256
        $result.Add([pscustomobject]@{
            path = $path
            hash = $h.Hash
            algo = $h.Algorithm
        })
    }
    else {
        $result.Add([pscustomobject]@{
            path = $path
            hash = $null
            algo = "MISSING"
        })
    }
}

$payload = [pscustomobject]@{
    generated_at = (Get-Date).ToString("s")
    files        = $result
}

$payload | ConvertTo-Json -Depth 5 | Set-Content -Path $lockPath -Encoding UTF8

& "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
    -Project "System" `
    -Agent "AZ-Lock" `
    -Action "write-lock" `
    -Status "success" `
    -Details "Lockfile updated at $lockPath"
