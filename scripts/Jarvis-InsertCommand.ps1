<#
    Jarvis-InsertCommand.ps1
    ------------------------
    Helper to insert commands into Supabase az_commands via REST.

    Usage (example):
      .\Jarvis-InsertCommand.ps1 `
        -Agent "fileops" `
        -Kind "write_file" `
        -PayloadObject @{ path = "F:\AION-ZERO\test\demo.txt"; content = "Hi"; encoding = "utf8" } `
        -Project "AION-ZERO" `
        -Priority 100
#>

param(
    [string]$Agent = "fileops",
    [string]$Kind,
    [hashtable]$PayloadObject,
    [string]$Project = "AION-ZERO",
    [int]$Priority = 100
)

# -------------------------
#  CONFIG FROM ENV
# -------------------------

$SupabaseUrl        = $env:SUPABASE_URL
$SupabaseServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $SupabaseUrl -or -not $SupabaseServiceKey) {
    Write-Host "[Jarvis-InsertCommand] ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set." -ForegroundColor Red
    exit 1
}

$CommandTable = "az_commands"

# -------------------------
#  HELPER: POST TO SUPABASE
# -------------------------

function Invoke-SupabasePost {
    param(
        [string]$RelativePath,
        [hashtable]$Body
    )

    $uri = "$SupabaseUrl/$RelativePath"

    $headers = @{
        "apikey"        = $SupabaseServiceKey
        "Authorization" = "Bearer $SupabaseServiceKey"
        "Content-Type"  = "application/json"
        "Prefer"        = "return=representation"
    }

    $json = $Body | ConvertTo-Json -Depth 20

    try {
        return Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $json
    } catch {
        Write-Host "[Jarvis-InsertCommand] Supabase POST failed: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response -and $_.Exception.Response.GetResponseStream()) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $errBody = $reader.ReadToEnd()
            Write-Host "[Jarvis-InsertCommand] Response body: $errBody" -ForegroundColor DarkRed
        }
        exit 1
    }
}

# -------------------------
#  BUILD & SEND COMMAND
# -------------------------

if (-not $Kind) {
    Write-Host "[Jarvis-InsertCommand] ERROR: -Kind is required (write_file / append_file / run_shell / ...)." -ForegroundColor Red
    exit 1
}

if (-not $PayloadObject) {
    $PayloadObject = @{}
}
$PayloadObject["kind"] = $Kind

$payloadJson = $PayloadObject | ConvertTo-Json -Depth 20

$body = @{
    agent   = $Agent
    status  = "queued"
    project = $Project
    priority = $Priority
    payload = $payloadJson
}

$result = Invoke-SupabasePost -RelativePath "rest/v1/$CommandTable" -Body $body

Write-Host "[Jarvis-InsertCommand] Inserted command:" -ForegroundColor Green
$result | Format-List
