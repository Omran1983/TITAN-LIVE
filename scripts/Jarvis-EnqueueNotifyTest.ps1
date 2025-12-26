$ErrorActionPreference = "Stop"

# --- CONFIG --------------------------------------------------------------

$SupabaseUrl = $env:SUPABASE_URL
$ServiceKey  = $env:SUPABASE_SERVICE_ROLE_KEY

if ([string]::IsNullOrWhiteSpace($SupabaseUrl)) {
    $SupabaseUrl = "https://abkprecmhitqmmlzxfad.supabase.co"
}

$CmdEndpoint = $env:AZ_COMMANDS_ENDPOINT
if ([string]::IsNullOrWhiteSpace($CmdEndpoint)) {
    $CmdEndpoint = "$SupabaseUrl/rest/v1/az_commands"
}

$ProjectName = $env:AZ_PROJECT_NAME
if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    $ProjectName = "AION-ZERO"
}

if ([string]::IsNullOrWhiteSpace($ServiceKey)) {
    throw "SUPABASE_SERVICE_ROLE_KEY is not set. Run Jarvis-LoadEnv.ps1 first."
}

Write-Host "EnqueueNotifyTest: endpoint = $CmdEndpoint"
Write-Host "EnqueueNotifyTest: project  = $ProjectName"

# --- HTTP HEADERS -------------------------------------------------------

$headers = @{
    apikey         = $ServiceKey
    Authorization  = "Bearer $ServiceKey"
    Prefer         = "return=representation"
    "Content-Type" = "application/json"
}

# --- BODY (NO 'payload' COLUMN) ----------------------------------------

$now = (Get-Date).ToString("o")

$bodyObj = @{
    project = $ProjectName
    action  = "notify"
    command = "notify.alert"
    status  = "queued"
    # If later you add a 'message' text column, we can include it here.
}

$bodyJson = $bodyObj | ConvertTo-Json -Depth 10

Write-Host "EnqueueNotifyTest: posting body:"
Write-Host $bodyJson

# --- POST TO SUPABASE WITH ERROR BODY DUMP ------------------------------

try {
    $response = Invoke-RestMethod -Method Post -Uri $CmdEndpoint -Headers $headers -Body $bodyJson
    Write-Host "EnqueueNotifyTest: response from Supabase:"
    $response | ConvertTo-Json -Depth 10
}
catch {
    Write-Host "EnqueueNotifyTest: ERROR calling Supabase (HTTP error)" -ForegroundColor Red

    $ex = $_.Exception
    Write-Host "Exception message: $($ex.Message)"

    if ($ex.Response -ne $null) {
        try {
            $respStream = $ex.Response.GetResponseStream()
            $reader     = New-Object System.IO.StreamReader($respStream)
            $respBody   = $reader.ReadToEnd()
            Write-Host "Supabase error body:"
            Write-Host $respBody
        }
        catch {
            Write-Host "Failed to read error response body."
        }
    } else {
        Write-Host "No response body available."
    }

    throw
}
