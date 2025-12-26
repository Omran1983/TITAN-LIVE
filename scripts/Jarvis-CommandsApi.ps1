<#
    Jarvis-CommandsApi.ps1
    ----------------------
    Minimal HTTP API for Jarvis commands:

      GET  /health
        -> { status: "ok", project: "...", time: "..." }

      POST /commands
        Body (JSON), superset of az_commands schema:
        {
          "project": "AION-ZERO",
          "agent": "DemoWorker",
          "source": "DemoWorker",
          "action": "code",
          "status": "queued",
          "instruction": "Demo instruction",
          "args": { ... },      // optional
          "payload": { ... }    // optional, used as fallback for args
        }

      Behaviour:
        - Normalises missing fields (project, status, args)
        - Inserts a row into az_commands via Supabase REST
        - Returns: { ok: true, message: "Command queued", id: <id> }

    Usage:

      cd F:\AION-ZERO\scripts
      powershell -NoProfile -ExecutionPolicy Bypass -File .\Jarvis-CommandsApi.ps1

    This script runs an HttpListener loop until you close the window.
#>

param(
    [string]$Project = "AION-ZERO",
    [int]$Port = 5051
)

$ErrorActionPreference = "Stop"

Write-Log "[CommandsApi] ScriptDir = $((Split-Path -Parent $MyInvocation.MyCommand.Path))"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path $scriptDir -Parent
Write-Log "[CommandsApi] RootDir   = $rootDir"

# Load env (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
. "$scriptDir\Jarvis-LoadEnv.ps1"
Write-Log "Loaded environment variables from F:\AION-ZERO\.env"

$supabaseUrl = $env:SUPABASE_URL
$serviceKey = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $supabaseUrl -or -not $serviceKey) {
    throw "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set in environment."
}

$headers = @{
    apikey        = $serviceKey
    Authorization = "Bearer $serviceKey"
    Prefer        = "return=representation"
}

# --- API Security ---
$apiKey = $env:JARVIS_COMMANDS_API_KEY
if (-not $apiKey -or $apiKey.Trim() -eq "") {
    Write-Log "JARVIS_COMMANDS_API_KEY not set in .env. API will be INSECURE (Development Mode)." -ForegroundColor Yellow
    $apiKey = $null
}
else {
    Write-Log "[CommandsApi] Secure Mode: X-API-KEY required." -ForegroundColor Green
}

# --- Helper: write JSON response ---
function Write-JsonResponse {
    param(
        [Parameter(Mandatory)][System.Net.HttpListenerResponse]$Response,
        [Parameter(Mandatory)][int]$StatusCode,
        [Parameter(Mandatory)][hashtable]$Body
    )

    $Response.StatusCode = $StatusCode
    $Response.ContentType = "application/json; charset=utf-8"

    $json = $Body | ConvertTo-Json -Depth 10

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $Response.ContentLength64 = $bytes.Length
    $Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $Response.OutputStream.Close()
}


# --------- Logging ---------

$logDir = Join-Path $rootDir "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
$logPath = Join-Path $logDir "Jarvis-CommandsApi.log"

function Write-Log {
    param(
        [string]$Message,
        [consolecolor]$ForegroundColor = "White"
    )
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] [INFO] $Message"
    Write-Host $line -ForegroundColor $ForegroundColor
    try { Add-Content -Path $logPath -Value $line -ErrorAction SilentlyContinue } catch {}
}

# --- Start HttpListener ---
$prefix = "http://127.0.0.1:$Port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
    Write-Log "[CommandsApi] Listening on $prefix" -ForegroundColor Cyan
    Write-Log "[CommandsApi] POST  /commands  -> enqueue az_commands"
    Write-Log "[CommandsApi] GET   /health    -> health check"
}
catch {
    Write-Log "[CommandsApi] FAILED TO START LISTENER: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

try {
    while ($true) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path = $request.Url.AbsolutePath.ToLowerInvariant()
        $method = $request.HttpMethod.ToUpperInvariant()

        # --- Auth Check ---
        if ($apiKey) {
            $clientKey = $request.Headers["X-API-KEY"]
            if (-not $clientKey -or $clientKey -ne $apiKey) {
                Write-Log "[CommandsApi] 401 Unauthorized (Invalid Key)" -ForegroundColor Red
                Write-JsonResponse -Response $response -StatusCode 401 -Body @{
                    ok      = $false
                    message = "Unauthorized"
                }
                continue
            }
        }


        if ($method -eq "GET" -and $path -eq "/health") {
            Write-Log "[CommandsApi] GET /health"
            $body = @{
                status  = "ok"
                project = $Project
                time    = (Get-Date).ToString("o")
            }
            Write-JsonResponse -Response $response -StatusCode 200 -Body $body
            continue
        }

        if ($method -eq "POST" -and $path -eq "/commands") {
            Write-Log "[CommandsApi] POST /commands"

            try {
                # Read request body as string
                $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
                $rawBody = $reader.ReadToEnd()
                $reader.Close()

                if ([string]::IsNullOrWhiteSpace($rawBody)) {
                    Write-Log "[CommandsApi] Empty request body."
                    Write-JsonResponse -Response $response -StatusCode 400 -Body @{
                        ok      = $false
                        message = "Empty request body."
                    }
                    continue
                }

                # Parse JSON
                try {
                    $payload = $rawBody | ConvertFrom-Json
                }
                catch {
                    $ex = $_.Exception
                    Write-Log "[CommandsApi] Invalid JSON: $($ex.Message)"
                    Write-JsonResponse -Response $response -StatusCode 400 -Body @{
                        ok      = $false
                        message = "Invalid JSON."
                        error   = $ex.Message
                    }
                    continue
                }

                # Normalise fields for az_commands insert
                $cmdProject = $payload.project
                if (-not $cmdProject -or $cmdProject.Trim() -eq "") {
                    $cmdProject = $Project
                }

                $cmdAgent = $payload.agent
                $cmdSource = $payload.source
                $cmdAction = $payload.action
                $cmdStatus = $payload.status
                $cmdInstruction = $payload.instruction
                $cmdArgs = $payload.args

                if (-not $cmdStatus -or $cmdStatus.Trim() -eq "") {
                    $cmdStatus = "queued"
                }

                if (-not $cmdArgs -and $payload.payload) {
                    # Fallback: use payload as args
                    $cmdArgs = $payload.payload
                }

                if (-not $cmdAction -or $cmdAction.Trim() -eq "") {
                    $cmdAction = "code"
                }

                if (-not $cmdInstruction) {
                    $cmdInstruction = "No instruction provided."
                }

                # Build Supabase body
                $insertBody = @(
                    @{
                        project     = $cmdProject
                        agent       = $cmdAgent
                        source      = $cmdSource
                        action      = $cmdAction
                        status      = $cmdStatus
                        instruction = $cmdInstruction
                        args        = $cmdArgs
                    }
                ) | ConvertTo-Json

                $commandsUrl = "$supabaseUrl/rest/v1/az_commands?select=*"

                $resp = Invoke-RestMethod -Method Post `
                    -Uri $commandsUrl `
                    -Headers $headers `
                    -ContentType "application/json" `
                    -Body $insertBody

                $cmdId = $null
                if ($resp -and $resp[0].id) {
                    $cmdId = $resp[0].id
                }

                Write-Log "[CommandsApi] Enqueued command id=$cmdId project=$cmdProject action=$cmdAction status=$cmdStatus"

                $responseBody = @{
                    ok      = $true
                    message = "Command queued."
                    id      = $cmdId
                }

                Write-JsonResponse -Response $response -StatusCode 200 -Body $responseBody
            }
            catch {
                $ex = $_.Exception
                Write-Log "[CommandsApi] ERROR: Unhandled request error: $($ex.Message)"
                Write-JsonResponse -Response $response -StatusCode 500 -Body @{
                    ok      = $false
                    message = "Internal server error."
                    error   = $ex.Message
                }
            }

            continue
        }

        # Unknown route
        Write-Log "[CommandsApi] $method $path -> 404"
        Write-JsonResponse -Response $response -StatusCode 404 -Body @{
            ok      = $false
            message = "Not found."
        }
    }
}
finally {
    $listener.Stop()
    $listener.Close()
}
