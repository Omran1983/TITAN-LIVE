# ReachX-QuickStatus.ps1
# Simple health check for ReachX Supabase tables (matching ReachX-Refresh-All style)

Write-Host "=== ReachX Quick Status $(Get-Date -Format o) ===" -ForegroundColor Cyan

# 1) Ensure ReachX env is loaded
. 'F:\tweakops\Use-ProjectEnv.ps1' -Project reachx

# 2) Get Supabase URL + key from ReachX env (same pattern as ReachX-Refresh-All)
$rawUrl = $env:REACHX_SUPABASE_URL
if (-not $rawUrl) {
    $rawUrl = $env:SBURL
}

if (-not $rawUrl) {
    Write-Host "ReachX-QuickStatus: No REACHX_SUPABASE_URL/SBURL found." -ForegroundColor Red
    return
}

$rawUrl = $rawUrl.TrimEnd('/')

# Build API base exactly once: .../rest/v1
if ($rawUrl -match '/rest/v1$') {
    $apiBase = $rawUrl
} else {
    $apiBase = "$rawUrl/rest/v1"
}

$sbKey = $env:REACHX_SUPABASE_SERVICE_KEY
if (-not $sbKey) {
    $sbKey = $env:SBKEY
}

if (-not $sbKey) {
    Write-Host "ReachX-QuickStatus: No REACHX_SUPABASE_SERVICE_KEY/SBKEY found." -ForegroundColor Red
    return
}

Write-Host "Supabase raw URL : $rawUrl" -ForegroundColor Yellow
Write-Host "Supabase API base: $apiBase" -ForegroundColor Yellow

$headers = @{
    apikey        = $sbKey
    Authorization = "Bearer $sbKey"
    "Content-Type" = "application/json"
}

$tables = @('workers', 'employers', 'agents', 'dormitories')

Write-Host ""
Write-Host "Table           Status           Details" -ForegroundColor Cyan
Write-Host "--------------  ---------------  ----------------------------------------"

foreach ($t in $tables) {
    # Build URL in a way that cannot drop the table name
    $uri = ("{0}/{1}?select=*&limit=1" -f $apiBase, $t)

    Write-Host ""
    Write-Host "Checking table '$t' via: $uri" -ForegroundColor DarkGray

    try {
        $resp  = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -ErrorAction Stop
        $count = @($resp).Count
        $detail = "sample rows: $count"
        Write-Host ("{0,-14}  {1,-15}  {2}" -f $t, "OK", $detail) -ForegroundColor Green
    }
    catch {
        $msg        = $_.Exception.Message
        $statusCode = $null
        $body       = $null

        if ($_.Exception.Response) {
            try {
                $statusCode = [int]$_.Exception.Response.StatusCode
            } catch { }

            if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
                $body = $_.ErrorDetails.Message
            } else {
                try {
                    $stream = $_.Exception.Response.GetResponseStream()
                    if ($stream) {
                        $reader = New-Object System.IO.StreamReader($stream)
                        $body = $reader.ReadToEnd()
                    }
                } catch { }
            }
        }

        $detail = "Status=$statusCode; Msg=$msg"
        if ($body) {
            $detail += "; Body=$body"
        }

        Write-Host ("{0,-14}  {1,-15}  {2}" -f $t, "ERROR", $detail) -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "ReachX Quick Status check complete."
