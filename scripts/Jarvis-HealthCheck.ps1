param(
    [int]$Limit = 10
)

cd F:\AION-ZERO
& "F:\AION-ZERO\scripts\Jarvis-LoadEnv.ps1" | Out-Null

$SUPABASE_URL = $env:SUPABASE_URL
$SERVICE_ROLE_KEY = $env:SUPABASE_SERVICE_ROLE_KEY

if ([string]::IsNullOrWhiteSpace($SUPABASE_URL) -or
    [string]::IsNullOrWhiteSpace($SERVICE_ROLE_KEY)) {
    Write-Host "ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set. Did you run Jarvis-LoadEnv.ps1?"
    exit 1
}

if ($SUPABASE_URL.EndsWith("/")) {
    $SUPABASE_URL = $SUPABASE_URL.TrimEnd("/")
}

$headers = @{
    apikey        = $SERVICE_ROLE_KEY
    Authorization = "Bearer $SERVICE_ROLE_KEY"
    Accept        = "application/json"
}

$uri = "$SUPABASE_URL/rest/v1/az_commands?order=created_at.desc&limit=$Limit"

$rows = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers

"=== Last $Limit commands in az_commands ==="
$rows | Select-Object id, project, action, command, status, created_at, updated_at
