<#
  Jarvis-CommandAgent.ps1
  - Polls az_commands for queued commands for a project
  - Executes PowerShell commands (action = 'powershell')
  - Updates status -> done / error
  - Enqueues notify rows so NotifyWorker can send Telegram messages
#>

param(
    [string]$ProjectNameParam,
    [int]$PollIntervalSeconds = 30
)

$ErrorActionPreference = "Stop"

# --- 0. LOAD .ENV ----------------------------------------------------------

try {
    if (Test-Path "F:\AION-ZERO\scripts\Jarvis-LoadEnv.ps1") {
        & "F:\AION-ZERO\scripts\Jarvis-LoadEnv.ps1"
    } else {
        Write-Host "[$(Get-Date -Format o)] [WARN] Jarvis-LoadEnv.ps1 not found at F:\AION-ZERO\scripts\Jarvis-LoadEnv.ps1"
    }
}
catch {
    Write-Host "[$(Get-Date -Format o)] [WARN] Failed to load .env via Jarvis-LoadEnv.ps1: $($_.Exception.Message)"
}

# --- 1. LOG HELPER ---------------------------------------------------------

function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$ts [$Level] $Message"
}

# --- 2. CONFIG RESOLUTION --------------------------------------------------

$DefaultSupabaseUrl     = "https://abkprecmhitqmmlzxfad.supabase.co"
$DefaultProjectName     = "AION-ZERO"

$SupabaseUrl = $env:SUPABASE_URL
$ServiceKey  = $env:SUPABASE_SERVICE_ROLE_KEY

if ([string]::IsNullOrWhiteSpace($SupabaseUrl)) {
    $SupabaseUrl = $DefaultSupabaseUrl
}

$CommandsUrl = $env:AZ_COMMANDS_ENDPOINT
if ([string]::IsNullOrWhiteSpace($CommandsUrl)) {
    $CommandsUrl = "$SupabaseUrl/rest/v1/az_commands"
}

$ProjectName = $ProjectNameParam
if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    $ProjectName = $env:AZ_PROJECT_NAME
}
if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    $ProjectName = $DefaultProjectName
}

if ([string]::IsNullOrWhiteSpace($CommandsUrl)) {
    throw "Commands URL is empty; cannot continue."
}

if ([string]::IsNullOrWhiteSpace($ServiceKey)) {
    Write-Log -Level "WARN" -Message "SUPABASE_SERVICE_ROLE_KEY is not set. Supabase requests may fail."
}

Write-Log -Level "INFO" -Message "START: Jarvis-CommandAgent v3 (baseline)"
Write-Log -Level "INFO" -Message ("DEBUG: SUPABASE_URL = {0}" -f $SupabaseUrl)
Write-Log -Level "INFO" -Message ("DEBUG: COMMANDS URL = {0}" -f $CommandsUrl)
Write-Log -Level "INFO" -Message ("Polling az_commands every {0} second(s)..." -f $PollIntervalSeconds)

# --- 3. SUPABASE HELPERS ---------------------------------------------------

function Get-Headers {
    return @{
        apikey            = $ServiceKey
        Authorization     = "Bearer $ServiceKey"
        "Content-Profile" = "public"
        "Accept-Profile"  = "public"
        Accept            = "application/json"
    }
}

function Get-QueuedCommands {
    param(
        [string]$ProjectName,
        [int]$Limit = 10
    )

    $query = @(
        "project=eq.$ProjectName"
        "status=eq.queued"
        "order=created_at.asc"
        "limit=$Limit"
    ) -join "&"

    $uri = "$CommandsUrl`?$query"

    Write-Log -Level "INFO" -Message ("DEBUG: GET {0}" -f $uri)

    $headers = Get-Headers

    try {
        $resp = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        return $resp
    }
    catch {
        Write-Log -Level "ERROR" -Message ("Error fetching queued commands: {0}" -f $_.Exception.Message)
        return @()
    }
}

function Update-CommandStatus {
    param(
        [Parameter(Mandatory = $true)][int]$Id,
        [Parameter(Mandatory = $true)][string]$Status,
        [string]$Logs
    )

    # Hard base URL to avoid any mutated/invalid CommandsUrl issues
    $base = "https://abkprecmhitqmmlzxfad.supabase.co/rest/v1/az_commands"
    $uri  = "$base?id=eq.$Id"

    Write-Log -Level "DEBUG" -Message ("DEBUG: PATCH URI = {0}" -f $uri)

    $body = @{
        status     = $Status
        updated_at = (Get-Date).ToString("o")
        agent      = "jarvis_command_agent"
    }

    if (-not [string]::IsNullOrWhiteSpace($Logs)) {
        # keep logs compact
        $body.logs = if ($Logs.Length -gt 2000) { $Logs.Substring(0,2000) } else { $Logs }
    }

    $json = $body | ConvertTo-Json -Depth 5

    $headers = Get-Headers
    $headers["Content-Type"] = "application/json"
    $headers["Prefer"]       = "return=minimal"

    try {
        Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -Body $json | Out-Null
        Write-Log -Level "DEBUG" -Message ("Updated az_commands id={0} status -> {1}" -f $Id, $Status)
    }
    catch {
        Write-Log -Level "ERROR" -Message ("Failed to update status for id={0}: {1}" -f $Id, $_.Exception.Message)
    }
}

function Enqueue-Notify {
    param(
        [string]$ProjectName,
        [string]$Message
    )

    if ([string]::IsNullOrWhiteSpace($Message)) {
        return
    }

    $uri = $CommandsUrl

    $body = @{
        project = $ProjectName
        action  = "notify"
        command = $Message
        status  = "queued"
    } | ConvertTo-Json

    $headers = Get-Headers
    $headers["Content-Type"] = "application/json"

    Write-Log -Level "DEBUG" -Message ("Enqueue notify: {0}" -f $Message)

    try {
        Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body | Out-Null
    }
    catch {
        Write-Log -Level "ERROR" -Message ("Failed to enqueue notify command: {0}" -f $_.Exception.Message)
    }
}

# --- 4. EXECUTION HELPERS --------------------------------------------------

function Execute-PowershellCommand {
    param(
        [int]$Id,
        [string]$CommandText
    )

    if ([string]::IsNullOrWhiteSpace($CommandText)) {
        Write-Log -Level "ERROR" -Message ("Command id={0} has empty command text." -f $Id)
        Update-CommandStatus -Id $Id -Status "error" -Logs "Empty command text."
        Enqueue-Notify -ProjectName $ProjectName -Message "Jarvis: powershell command id=$Id failed (empty command)."
        return
    }

    Write-Log -Level "INFO" -Message ("Executing PowerShell command for id={0}" -f $Id)
    Write-Host  "-----"
    Write-Host  $CommandText
    Write-Host  "-----"

    try {
        # Execute in current process; for more isolation we could spawn a child process.
        Invoke-Expression $CommandText

        Update-CommandStatus -Id $Id -Status "done" -Logs "Executed successfully."
        Enqueue-Notify -ProjectName $ProjectName -Message "Jarvis: powershell command id=$Id executed successfully at $(Get-Date -Format o)."
    }
    catch {
        $err = $_.Exception.Message
        Write-Log -Level "ERROR" -Message ("Error executing command id={0}: {1}" -f $Id, $err)
        Update-CommandStatus -Id $Id -Status "error" -Logs $err
        Enqueue-Notify -ProjectName $ProjectName -Message "Jarvis ERROR: powershell command id=$Id failed: $err"
    }
}

# --- 5. MAIN LOOP ----------------------------------------------------------

while ($true) {
    Write-Log -Level "INFO" -Message "Polling az_commands for queued items..."

    $rows = Get-QueuedCommands -ProjectName $ProjectName -Limit 10

    if ($rows -and $rows.Count -gt 0) {
        foreach ($row in $rows) {
            $id      = [int]$row.id
            $action  = $row.action
            $status  = $row.status
            $project = $row.project

            Write-Log -Level "DEBUG" -Message ("Row id={0}, project={1}, action={2}, status={3}" -f $id, $project, $action, $status)

            if ($project -ne $ProjectName) {
                continue
            }

            if ($status -ne "queued") {
                continue
            }

            switch ($action) {
                "powershell" {
                    Execute-PowershellCommand -Id $id -CommandText $row.command
                }
                default {
                    # For now, mark non-powershell commands as 'ignored' to avoid blocking the queue
                    Write-Log -Level "INFO" -Message ("Ignoring unsupported action '{0}' for id={1}" -f $action, $id)
                    Update-CommandStatus -Id $id -Status "ignored" -Logs "Unsupported action by Jarvis-CommandAgent."
                }
            }
        }
    }
    else {
        Write-Log -Level "INFO" -Message "No suitable queued commands found."
    }

    Start-Sleep -Seconds $PollIntervalSeconds
}
