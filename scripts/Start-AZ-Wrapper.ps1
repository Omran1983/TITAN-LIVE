$ErrorActionPreference = "Stop"

& "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
    -Project "System" `
    -Agent "Start-AZ" `
    -Action "start" `
    -Status "running" `
    -Details "Start-AZ wrapper tick"

try {
    & "F:\AION-ZERO\scripts\Start-AZ.ps1"

    & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
        -Project "System" `
        -Agent "Start-AZ" `
        -Action "done" `
        -Status "success" `
        -Details "Start-AZ completed"
}
catch {
    & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
        -Project "System" `
        -Agent "Start-AZ" `
        -Action "error" `
        -Status "error" `
        -Details $_.Exception.Message

    throw
}
