param(
    [string]$HostName = $env:COMPUTERNAME,
    [string]$Project,
    [string]$Action,
    [hashtable]$Payload
)

$ErrorActionPreference = "Stop"

if (-not $Project) { throw "Project is required (e.g. ReachX, EduConnect)." }
if (-not $Action)  { throw "Action is required (e.g. reachx_refresh)." }

# Load JARVIS env (az project = JARVIS Supabase)
. 'F:\tweakops\Use-ProjectEnv.ps1' -Project az

$supabaseInfo = & 'F:\AION-ZERO\scripts\Load-Supabase.ps1'
$sbUrl = $supabaseInfo.Url.TrimEnd('/')
$sbKey = $supabaseInfo.Key

$headers = @{
    apikey         = $sbKey
    Authorization  = "Bearer $sbKey"
    "Content-Type" = "application/json"
    Prefer         = "return=representation"
}

$payloadJson = $null
if ($Payload) {
    $payloadJson = ($Payload | ConvertTo-Json -Depth 10 | ConvertFrom-Json)
}

$body = @{
    host_name = $HostName
    project   = $Project
    action    = $Action
    payload   = $payloadJson
    status    = "queued"
} | ConvertTo-Json -Depth 10

$uri = "$sbUrl/rest/v1/bridge_commands"

Write-Host "Enqueuing bridge command to $uri..."
$result = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body

$result
