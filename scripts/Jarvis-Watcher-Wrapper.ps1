$ErrorActionPreference = "Stop"

& "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
    -Project "System" `
    -Agent "Jarvis-Watcher" `
    -Action "start" `
    -Status "running" `
    -Details "Jarvis watcher tick"

try {
    & "F:\AION-ZERO\scripts\Jarvis-Watcher.ps1"

    & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
        -Project "System" `
        -Agent "Jarvis-Watcher" `
        -Action "done" `
        -Status "success" `
        -Details "Jarvis watcher completed"
}
catch {
    & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
        -Project "System" `
        -Agent "Jarvis-Watcher" `
        -Action "error" `
        -Status "error" `
        -Details $_.Exception.Message

    throw
}
