# F:\AION-ZERO\scripts\Enqueue-AZCommand.ps1
param(
    [Parameter(Mandatory = $true)]
    [string]$Command,

    [string]$Project      = "System",
    [string]$TargetAgent  = "AION-ZERO",
    [hashtable]$Args      = @{}
)

$ErrorActionPreference = "Stop"

. "F:\AION-ZERO\scripts\Load-Supabase.ps1"

$baseUri = "$SBURL/rest/v1/az_commands"

$headers = $SBHeaders.Clone()
$headers["Content-Type"] = "application/json"
$headers["Prefer"]       = "return=representation"

$body = @{
    project      = $Project
    target_agent = $TargetAgent
    command      = $Command
    args         = $Args
    status       = "pending"
} | ConvertTo-Json -Depth 5

$resp = Invoke-RestMethod -Uri $baseUri -Headers $headers -Method Post -Body $body

$id = $resp[0].id

& "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
    -Project "System" `
    -Agent "AZ-CommandEnqueue" `
    -Action "enqueue" `
    -Status "success" `
    -Details ("Enqueued command {0} (id={1})" -f $Command, $id)

Write-Host "Enqueued az_command id=$id command=$Command"
