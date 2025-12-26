param(
    [string]$ProjectNameParam,
    [int]$PollSeconds = 15,
    [int]$CommandId = 0,
    [switch]$SingleRun
)

$ErrorActionPreference = "Stop"

# --- 0. LOAD .ENV ----------------------------------------------------------
try {
    if (Test-Path "F:\AION-ZERO\scripts\Jarvis-LoadEnv.ps1") {
        & "F:\AION-ZERO\scripts\Jarvis-LoadEnv.ps1"
    }
    else {
        Write-Warning "Jarvis-LoadEnv.ps1 not found"
    }
}
catch {
    Write-Warning "Failed to load .env: $_"
}

# --- 1. DEFAULTS -----------------------------------------------------------
$DefaultSupabaseUrl = "https://abkprecmhitqmmlzxfad.supabase.co"
$DefaultCommandsEndpoint = "$DefaultSupabaseUrl/rest/v1/az_commands"
$DefaultProjectName = "AION-ZERO"

# --- 2. CONFIG -------------------------------------------------------------
$SupabaseUrl = $env:SUPABASE_URL
$ServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY
if ([string]::IsNullOrWhiteSpace($ServiceKey)) { $ServiceKey = $env:SUPABASE_SERVICE_KEY }

if ([string]::IsNullOrWhiteSpace($SupabaseUrl)) { $SupabaseUrl = $DefaultSupabaseUrl }
$CmdEndpoint = $env:AZ_COMMANDS_ENDPOINT
if ([string]::IsNullOrWhiteSpace($CmdEndpoint)) { $CmdEndpoint = "$SupabaseUrl/rest/v1/az_commands" }

$ProjectName = if ($ProjectNameParam) { $ProjectNameParam } elseif ($env:AZ_PROJECT_NAME) { $env:AZ_PROJECT_NAME } else { $DefaultProjectName }

if ([string]::IsNullOrWhiteSpace($CmdEndpoint)) { throw "Commands endpoint is empty; cannot continue." }

Write-Host "NotifyWorker [$((Get-Date).ToString("o"))] Project: $ProjectName | SingleRun: $SingleRun"

# --- 3. TELEGRAM -----------------------------------------------------------
function Send-TelegramMessage {
    param([string]$Text)

    $token = $env:TELEGRAM_BOT_TOKEN
    $chatId = $env:TELEGRAM_CHAT_ID

    if ([string]::IsNullOrWhiteSpace($chatId)) { $chatId = "1920600504" } # Fallback
    if ([string]::IsNullOrWhiteSpace($token)) { Write-Warning "TELEGRAM_BOT_TOKEN missing"; return }

    $uri = "https://api.telegram.org/bot$token/sendMessage"
    $body = @{ chat_id = $chatId; text = $Text }

    try {
        Invoke-RestMethod -Method Post -Uri $uri -Body $body | Out-Null
        Write-Host "NotifyWorker Telegram sent."
    }
    catch {
        Write-Host "NotifyWorker Telegram ERROR: $($_.Exception.Message)"
    }
}

# --- 4. SUPABASE HELPERS ---------------------------------------------------

function Get-Headers {
    return @{
        apikey            = $ServiceKey
        Authorization     = "Bearer $ServiceKey"
        "Content-Profile" = "public"
        "Accept-Profile"  = "public"
    }
}

function Get-NextNotifyCommand {
    param([int]$TargetId)

    if ($TargetId -gt 0) {
        $query = "select=*&id=eq.$TargetId"
    }
    else {
        $query = "select=*&project=eq.$ProjectName&action=eq.notify&status=eq.queued&order=created_at.asc&limit=1"
    }
    
    $url = "$CmdEndpoint?$query"
    $headers = Get-Headers
    return Invoke-RestMethod -Method Get -Uri $url -Headers $headers
}

function Update-CommandStatus {
    param([int]$Id, [string]$Status, [string]$ErrorMessage)

    $url = "$CmdEndpoint?id=eq.$Id"
    $body = @{
        status     = $Status
        updated_at = (Get-Date).ToString("o")
        agent      = "jarvis_notify_worker"
    }
    if ($ErrorMessage) { $body.logs = $ErrorMessage }

    $headers = Get-Headers
    $headers["Content-Type"] = "application/json"
    $headers["Prefer"] = "return=minimal"

    Invoke-RestMethod -Method Patch -Uri $url -Headers $headers -Body ($body | ConvertTo-Json -Depth 5) | Out-Null
}

# --- 5. MAIN LOOP ----------------------------------------------------------

while ($true) {
    try {
        if ($SingleRun -and $CommandId -gt 0) {
            $cmds = Get-NextNotifyCommand -TargetId $CommandId
        }
        else {
            $cmds = Get-NextNotifyCommand
        }

        if (-not $cmds -or $cmds.Count -eq 0) {
            if ($SingleRun) { Write-Warning "Command #$CommandId not found."; exit }
            Start-Sleep -Seconds $PollSeconds
            continue
        }

        if ($cmds -is [System.Array]) { $cmd = $cmds[0] } else { $cmd = $cmds }

        $id = [int]$cmd.id
        $action = $cmd.action
        $command = $cmd.command
        $status = $cmd.status

        $msg = if ($command) { $command } else { "Jarvis notify ($ProjectName): id=$id action=$action" }

        Write-Host "NotifyWorker Processing #$id: '$msg'"
        Update-CommandStatus -Id $id -Status "in_progress"
        Send-TelegramMessage -Text $msg
        Update-CommandStatus -Id $id -Status "done"
    }
    catch {
        Write-Host "NotifyWorker ERROR: $($_.Exception.Message)" -ForegroundColor Red
        if ($SingleRun) { exit 1 }
        Start-Sleep -Seconds $PollSeconds
    }

    if ($SingleRun) { break }
}
