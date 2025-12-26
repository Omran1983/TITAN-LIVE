$ErrorActionPreference = "Stop"

& "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
    -Project "System" `
    -Agent "AZ-Health" `
    -Action "start" `
    -Status "running" `
    -Details "Invoke-AZHealth wrapper tick"

try {
    # Make sure any relative paths (like .\logs) resolve under F:\AION-ZERO
    Push-Location "F:\AION-ZERO"
    try {
        & "F:\AION-ZERO\scripts\Invoke-AZHealth.ps1"
    }
    finally {
        Pop-Location
    }

    & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
        -Project "System" `
        -Agent "AZ-Health" `
        -Action "done" `
        -Status "success" `
        -Details "Invoke-AZHealth completed"
}
catch {
    & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
        -Project "System" `
        -Agent "AZ-Health" `
        -Action "error" `
        -Status "error" `
        -Details $_.Exception.Message

    throw
}
