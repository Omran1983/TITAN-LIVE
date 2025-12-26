<#
.SYNOPSIS
    Client Helper for Jarvis Mesh.
    Sends a payload to the Mesh Proxy, which routes it to the correct Agent.

.EXAMPLE
    .\Invoke-Mesh.ps1 -Source "Jarvis-CodeAgent" -RouteKey "brain.alert" -Payload @{ message = "Build Success" }
#>

param(
    [string]$Source = "Jarvis-GenericClient",
    [string]$RouteKey,
    [hashtable]$Payload,
    [string]$ProxyUrl = "http://127.0.0.1:5055/route"
)

$Body = @{
    source_agent = $Source
    route_key    = $RouteKey
    payload      = $Payload
} | ConvertTo-Json -Depth 10

try {
    $Response = Invoke-RestMethod -Uri $ProxyUrl -Method Post -Body $Body -ContentType "application/json" -ErrorAction Stop
    return $Response
}
catch {
    Write-Error "Mesh Call Failed: $_"
    return $null
}
