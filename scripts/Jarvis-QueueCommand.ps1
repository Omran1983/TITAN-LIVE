<#
    Jarvis-QueueCommand.ps1
    -----------------------
    Enqueue a command into az_commands for a given project.

    This version is BACKWARD COMPATIBLE with your existing schema:
      - Does NOT send an 'instruction' column (which caused 400 errors).
      - Instead, if -Instruction is provided, it is embedded into args JSON.

    Usage examples:

      # Old style (still works)
      powershell -NoProfile -ExecutionPolicy Bypass -File .\Jarvis-QueueCommand.ps1 `
        -Project "reachx" `
        -Action "code" `
        -ArgsText '{ "limit": "scaffold_only" }'

      # New style with instruction embedded in args JSON
      powershell -NoProfile -ExecutionPolicy Bypass -File .\Jarvis-QueueCommand.ps1 `
        -Project "reachx" `
        -Action "code" `
        -Instruction "Refactor Employer screen: make the form primary, move the table into a collapsible section below, and add a Settings tab scaffold." `
        -ArgsText '{ "limit": "scaffold_only" }'
#>

param(
    [Parameter(Mandatory = $true)][string]$Project,
    [Parameter(Mandatory = $true)][string]$Action,
    [string]$Agent,
    [string]$Source,
    [string]$Instruction,
    [string]$ArgsText
)

$ErrorActionPreference = "Stop"

# Resolve script dir and load env
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptDir\Jarvis-LoadEnv.ps1"

$supabaseUrl = $env:SUPABASE_URL
$serviceKey  = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $supabaseUrl -or -not $serviceKey) {
    throw "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set in environment."
}

$headers = @{
    apikey        = $serviceKey
    Authorization = "Bearer $serviceKey"
    Prefer        = "return=representation"
}

Write-Host "=== Jarvis-QueueCommand ==="
Write-Host "Project  : $Project"
Write-Host "Action   : $Action"
Write-Host "Status   : queued"
if ($Agent)       { Write-Host "Agent    : $Agent" }
if ($Source)      { Write-Host "Source   : $Source" }
if ($Instruction) { Write-Host "Instruction: $Instruction" }
if ($ArgsText)    { Write-Host "ArgsText : $ArgsText" }

# --- Build args string (embed Instruction INSIDE args JSON, no new column) ---

$stringArgs = $null

if ($Instruction -and $ArgsText) {
    # Try to parse ArgsText as JSON and merge instruction into it
    try {
        $argsObj = $ArgsText | ConvertFrom-Json
    }
    catch {
        # If ArgsText isn't valid JSON, wrap it
        $argsObj = [PSCustomObject]@{
            raw = $ArgsText
        }
    }

    # Ensure we have an object we can add properties to
    if (-not ($argsObj -is [System.Management.Automation.PSCustomObject])) {
        $argsObj = [PSCustomObject]@{
            value = $argsObj
        }
    }

    # Add/override "instruction" property
    $argsObj | Add-Member -NotePropertyName "instruction" -NotePropertyValue $Instruction -Force

    # Compact JSON string
    $stringArgs = $argsObj | ConvertTo-Json -Depth 10 -Compress
}
elseif ($Instruction -and -not $ArgsText) {
    # Only instruction → build minimal args JSON
    $argsObj = [PSCustomObject]@{
        instruction = $Instruction
    }
    $stringArgs = $argsObj | ConvertTo-Json -Depth 10 -Compress
}
elseif ($ArgsText) {
    # Only ArgsText → keep as-is (backward compatible)
    $stringArgs = $ArgsText
}

# --- Build body for Supabase insert ---

$body = @{
    project = $Project
    action  = $Action
    status  = "queued"
}

if ($Agent)      { $body.agent  = $Agent }
if ($Source)     { $body.source = $Source }
if ($stringArgs) { $body.args   = $stringArgs }

$bodyJson = @($body) | ConvertTo-Json -Depth 10

$url = "$supabaseUrl/rest/v1/az_commands?select=*"

Write-Host "POST $url"
Write-Host "Body:"
Write-Host $bodyJson

try {
    $resp = Invoke-RestMethod -Method Post `
        -Uri $url `
        -Headers $headers `
        -ContentType "application/json" `
        -Body $bodyJson

    if ($resp -is [System.Array]) {
        $row = $resp[0]
    } else {
        $row = $resp
    }

    $id = $row.id
    if ($id) {
        Write-Host "✅ Command queued with id = $id"
    } else {
        Write-Warning "Command queued but no id returned:"
        $resp | ConvertTo-Json -Depth 10
    }
}
catch {
    Write-Warning ("✗ Supabase insert failed: {0}" -f $_.Exception.Message)

    if ($_.Exception.Response -and $_.Exception.Response.GetResponseStream()) {
        $reader   = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $respBody = $reader.ReadToEnd()
        Write-Host "Supabase error response:"
        Write-Host $respBody
    }

    throw
}
