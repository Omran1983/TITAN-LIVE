<# 
    Jarvis-EndpointHealth.ps1
    -------------------------
    Pings key HTTP endpoints and updates az_mesh_endpoints.

    Usage:
        Run as a Scheduled Task every 1–2 minutes.

    Requires env:
        AZ_SUPABASE_URL (or SUPABASE_URL)
        AZ_SUPABASE_SERVICE_KEY (or SUPABASE_SERVICE_ROLE_KEY)
#>

$ErrorActionPreference = "Stop"

function Get-SupabaseConfig {
    # Env Var Fallback Logic
    $supabaseUrl = if ($env:AZ_SUPABASE_URL) { $env:AZ_SUPABASE_URL } else { $env:SUPABASE_URL }
    $supabaseKey = if ($env:AZ_SUPABASE_SERVICE_KEY) { $env:AZ_SUPABASE_SERVICE_KEY } else { $env:SUPABASE_SERVICE_ROLE_KEY }

    if (-not $supabaseUrl -or -not $supabaseKey) {
        throw "Supabase env vars missing. Ensure AZ_SUPABASE_URL or SUPABASE_URL is set."
    }

    return @{
        Url = $supabaseUrl
        Key = $supabaseKey
    }
}

function Upsert-EndpointStatus {
    param(
        [string] $Name,
        [string] $Url,
        [string] $Status,
        [int]    $LatencyMs,
        [string] $LastError = $null
    )

    $cfg = Get-SupabaseConfig

    $tableUrl = "$($cfg.Url)/rest/v1/az_mesh_endpoints?on_conflict=name"

    $headers = @{
        "apikey"        = $cfg.Key
        "Authorization" = "Bearer $($cfg.Key)"
        "Content-Type"  = "application/json"
        "Prefer"        = "resolution=merge-duplicates"
    }

    $payload = @{
        name         = $Name
        url          = $Url
        status       = $Status
        last_checked = (Get-Date).ToString("o")
        latency_ms   = $LatencyMs
        last_error   = $LastError
    }

    $json = $payload | ConvertTo-Json -Depth 5

    Invoke-RestMethod -Method Post -Uri $tableUrl -Headers $headers -Body $json | Out-Null
}

function Test-Endpoint {
    param(
        [string] $Name,
        [string] $Url
    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $status = "ok"
    $err = $null

    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -ge 400) {
            $status = "error"
            $err = "HTTP $($response.StatusCode)"
        }
    }
    catch {
        $status = "down"
        $err = $_.Exception.Message
    }
    finally {
        $sw.Stop()
    }

    $lat = [int]$sw.ElapsedMilliseconds
    Upsert-EndpointStatus -Name $Name -Url $Url -Status $status -LatencyMs $lat -LastError $err
    Write-Host "[ENDPOINT] $Name -> $status (${lat}ms) $Url"
}

try {
    Write-Host "[ENDPOINT] Starting endpoint health check..."

    # Adjust names/URLs to match your real setup
    Test-Endpoint -Name "Citadel-UI"      -Url "http://127.0.0.1:5000/"
    Test-Endpoint -Name "CommandsApi"     -Url "http://127.0.0.1:5051/health"
    Test-Endpoint -Name "MeshProxy"       -Url "http://127.0.0.1:5055/mesh"

    Write-Host "[ENDPOINT] Endpoint health check complete."
}
catch {
    Write-Host "[ENDPOINT] ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
