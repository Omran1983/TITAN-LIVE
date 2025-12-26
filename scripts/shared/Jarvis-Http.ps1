# Jarvis-Http.ps1

function Invoke-JarvisSupabase {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("GET","POST","PATCH","DELETE")]
        [string]$Method,
        [Parameter(Mandatory)]
        [string]$Path,        # e.g. "/rest/v1/az_commands"
        [hashtable]$Headers,
        [object]$Body,
        [int]$TimeoutSeconds = 30
    )

    if (-not $Headers) { $Headers = @{} }

    if (-not $Headers.ContainsKey("apikey") -and $env:SUPABASE_SERVICE_ROLE_KEY) {
        $Headers["apikey"] = $env:SUPABASE_SERVICE_ROLE_KEY
    }
    if (-not $Headers.ContainsKey("Authorization") -and $env:SUPABASE_SERVICE_ROLE_KEY) {
        $Headers["Authorization"] = "Bearer " + $env:SUPABASE_SERVICE_ROLE_KEY
    }

    $baseUrl = $env:SUPABASE_URL
    if (-not $baseUrl) {
        throw "SUPABASE_URL env var is not set."
    }

    $uri = "$baseUrl$Path"

    $params = @{
        Method  = $Method
        Uri     = $uri
        Headers = $Headers
        TimeoutSec = $TimeoutSeconds
    }

    if ($Body) {
        $json = $Body | ConvertTo-Json -Depth 20
        $params["Body"] = $json
        $params["ContentType"] = "application/json"
    }

    return Invoke-RestMethod @params
}

# Export-ModuleMember is only valid inside a .psm1 module.
# Commented out for dot-sourced usage.
# Export-ModuleMember -Function Invoke-JarvisSupabase