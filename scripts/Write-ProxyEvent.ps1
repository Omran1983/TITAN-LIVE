param(
    [Parameter(Mandatory = $true)]
    [string]$Project,

    [Parameter(Mandatory = $true)]
    [string]$Agent,

    [Parameter(Mandatory = $true)]
    [string]$Action,

    [string]$Status  = "success",
    [string]$Details = $null
)

# Load Supabase config (SBURL, SBHeaders)
. "F:\AION-ZERO\scripts\Load-Supabase.ps1"

# Build JSON body
$body = @{
    project = $Project
    agent   = $Agent
    action  = $Action
    status  = $Status
    details = $Details
} | ConvertTo-Json

# Clone headers and add content-type
$headers = $SBHeaders.Clone()
$headers["Content-Type"] = "application/json"
$headers["Prefer"]       = "return=minimal"

$uri = "$SBURL/rest/v1/proxy_events"

Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body | Out-Null

Write-Host "Logged proxy_event: $Project / $Agent / $Action / $Status"
