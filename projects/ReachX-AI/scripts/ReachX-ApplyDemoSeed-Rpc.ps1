Param(
    [string]$SupabaseUrl = "https://abkprecmhitqmmlzxfad.supabase.co",
    [string]$ServiceKey  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia3ByZWNtaGl0cW1tbHp4ZmFkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTk0NzY1OSwiZXhwIjoyMDc1NTIzNjU5fQ.-NrAHBNJOefsKpN_UIKhHNSukh7-ABO13IQjfNLswY4"
)

Write-Host "=== ReachX-ApplyDemoSeed-Rpc.ps1 ===" -ForegroundColor Cyan
Write-Host "Calling RPC reachx_apply_demo_seed() via HTTPS..." -ForegroundColor Yellow

if (-not $ServiceKey -or $ServiceKey -eq "YOUR_SERVICE_ROLE_KEY_HERE") {
    Write-Error "Please set -ServiceKey to your Supabase service_role key."
    exit 1
}

$uri = "$SupabaseUrl/rest/v1/rpc/reachx_apply_demo_seed"

$headers = @{
    "apikey"        = $ServiceKey
    "Authorization" = "Bearer $ServiceKey"
    "Content-Type"  = "application/json"
}

try {
    $body = "{}"
    $resp = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
    Write-Host "RPC call succeeded." -ForegroundColor Green
    if ($resp) {
        Write-Host "Response:" $resp
    } else {
        Write-Host "Response: (no body, success status)" 
    }
    exit 0
}
catch {
    Write-Error "RPC call failed: $($_.Exception.Message)"
    # Try to print response body if available (HTTP error response)
    if ($_.Exception.PSObject.Properties.Name -contains "Response" -and
        $null -ne $_.Exception.Response) {

        try {
            $respBody = $_.Exception.Response.Content.ReadAsStringAsync().Result
            Write-Host "Response body:" $respBody
        } catch {
            # Best effort only; ignore secondary errors
        }
    }
    exit 1
}
