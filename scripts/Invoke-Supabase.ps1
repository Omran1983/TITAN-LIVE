# F:\AION-ZERO\scripts\Invoke-Supabase.ps1
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,              # e.g. "/rest/v1/proxy_events"

    [Parameter(Mandatory = $false)]
    [ValidateSet("GET", "POST", "PATCH", "DELETE")]
    [string]$Method = "GET",

    [Parameter(Mandatory = $false)]
    [hashtable]$Query = @{},    # converted to query string

    [Parameter(Mandatory = $false)]
    [object]$Body = $null,      # hashtable/array -> JSON
       
    [switch]$ReturnRaw
)

$ErrorActionPreference = "Stop"

. "F:\AION-ZERO\scripts\Load-Supabase.ps1"

# Build query string
if ($Query.Count -gt 0) {
    $pairs = $Query.GetEnumerator() | ForEach-Object {
        [System.Uri]::EscapeDataString($_.Key) + "=" + [System.Uri]::EscapeDataString([string]$_.Value)
    }
    $qs = "?" + ($pairs -join "&")
}
else {
    $qs = ""
}

$SBURL = $env:SUPABASE_URL
if (-not $SBURL) { throw "Invoke-Supabase: SUPABASE_URL env var not found." }

$SBHeaders = @{
    "apikey"        = $env:SUPABASE_SERVICE_KEY
    "Authorization" = "Bearer $($env:SUPABASE_SERVICE_KEY)"
}

$uri = "$SBURL$Path$qs"

$headers = $SBHeaders.Clone()
$payload = $null

if ($null -ne $Body) {
    $payload = $Body | ConvertTo-Json -Depth 10
    $headers["Content-Type"] = "application/json"
}

if ($Method -eq "GET") {
    $resp = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
}
elseif ($Method -eq "POST") {
    $resp = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $payload
}
elseif ($Method -eq "PATCH") {
    $resp = Invoke-RestMethod -Uri $uri -Headers $headers -Method Patch -Body $payload
}
elseif ($Method -eq "DELETE") {
    $resp = Invoke-RestMethod -Uri $uri -Headers $headers -Method Delete -Body $payload
}
else {
    throw "Unsupported method: $Method"
}

if ($ReturnRaw) {
    return $resp
}
else {
    $resp | ConvertTo-Json -Depth 10
}
