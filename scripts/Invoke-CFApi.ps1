# F:\AION-ZERO\scripts\Invoke-CFApi.ps1
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,              # e.g. "/zones", "/zones/$CF_ZONE_ID_JARVIS/workers/scripts"
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("GET","POST","PUT","PATCH","DELETE")]
    [string]$Method = "GET",

    [Parameter(Mandatory = $false)]
    [hashtable]$Query = @{},    # converted to query string

    [Parameter(Mandatory = $false)]
    [object]$Body = $null,      # hashtable/array -> JSON

    [switch]$ReturnRaw
)

$ErrorActionPreference = "Stop"

. "F:\AION-ZERO\scripts\Load-Cloudflare.ps1"

$base = "https://api.cloudflare.com/client/v4"

# Build query string
if ($Query.Count -gt 0) {
    $pairs = $Query.GetEnumerator() | ForEach-Object {
        [System.Uri]::EscapeDataString($_.Key) + "=" + [System.Uri]::EscapeDataString([string]$_.Value)
    }
    $qs = "?" + ($pairs -join "&")
} else {
    $qs = ""
}

# Normalise path
if ($Path.StartsWith("/")) {
    $Path = $Path
} else {
    $Path = "/$Path"
}

$uri = "$base$Path$qs"

$headers = $CFHeaders.Clone()
$payload = $null

if ($Body -ne $null) {
    $payload = $Body | ConvertTo-Json -Depth 10
}

if ($Method -eq "GET") {
    $resp = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
} elseif ($Method -eq "POST") {
    $resp = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $payload
} elseif ($Method -eq "PUT") {
    $resp = Invoke-RestMethod -Uri $uri -Headers $headers -Method Put -Body $payload
} elseif ($Method -eq "PATCH") {
    $resp = Invoke-RestMethod -Uri $uri -Headers $headers -Method Patch -Body $payload
} elseif ($Method -eq "DELETE") {
    $resp = Invoke-RestMethod -Uri $uri -Headers $headers -Method Delete -Body $payload
} else {
    throw "Unsupported method: $Method"
}

if ($ReturnRaw) {
    return $resp
} else {
    $resp | ConvertTo-Json -Depth 10
}
