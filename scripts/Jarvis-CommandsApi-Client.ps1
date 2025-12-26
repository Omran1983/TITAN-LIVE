param()

<#
.SYNOPSIS
    Shared client helper for Jarvis Commands API.

.DESCRIPTION
    Provides Test-JarvisCommandsApiHealth and Send-JarvisCommand
    so any worker can enqueue commands via http://127.0.0.1:5051/commands.
#>

$ErrorActionPreference = "Stop"

# Base URL for Commands API (can be overridden via env var)
if ([string]::IsNullOrWhiteSpace($env:COMMANDS_API_BASE_URL)) {
    $script:CommandsApiBaseUrl = "http://127.0.0.1:5051"
} else {
    $script:CommandsApiBaseUrl = $env:COMMANDS_API_BASE_URL.TrimEnd("/")
}

function Test-JarvisCommandsApiHealth {
    try {
        $uri = "$script:CommandsApiBaseUrl/health"
        return Invoke-RestMethod -Method Get -Uri $uri
    }
    catch {
        throw "CommandsApi /health check failed at '$($script:CommandsApiBaseUrl)': $($_.Exception.Message)"
    }
}

function Send-JarvisCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Project,

        [Parameter(Mandatory = $true)]
        [string] $Action,

        [Parameter(Mandatory = $true)]
        [hashtable] $Payload,

        [hashtable] $Meta
    )

    $uri = "$script:CommandsApiBaseUrl/commands"

    # Serialize payload to JSON string – this is what backend likely expects
    $payloadJson = $Payload | ConvertTo-Json -Depth 10

    $body = [ordered]@{
        project      = $Project
        action       = $Action
        payload_json = $payloadJson
    }

    if ($Meta) {
        # Optional extra metadata if CommandsApi supports it
        $body.meta = $Meta
    }

    $jsonBody = $body | ConvertTo-Json -Depth 10

    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Body $jsonBody -ContentType "application/json"
        return $response
    }
    catch {
        throw "Send-JarvisCommand failed (POST $uri): $($_.Exception.Message)"
    }
}
