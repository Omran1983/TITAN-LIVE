# F:\AION-ZERO\scripts\Ping-Infra.ps1

$ErrorActionPreference = "Stop"

. "F:\AION-ZERO\scripts\Load-Supabase.ps1"

$details = "Ping-Infra " + (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")

& "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
    -Project "System" `
    -Agent "Infra" `
    -Action "ping" `
    -Status "success" `
    -Details $details

& "F:\AION-ZERO\scripts\Test-Infra.ps1"
