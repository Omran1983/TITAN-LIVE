<#
    Jarvis-FileOpsWorker.ps1
    ------------------------
    Polls Supabase az_commands for "fileops" tasks and executes them locally:
      - write_file / append_file
      - run_shell

    Requirements:
      - PowerShell 5+ (or pwsh)
      - Environment variables:
          SUPABASE_URL
          SUPABASE_SERVICE_ROLE_KEY   (or any key allowed to update az_commands)
      - az_commands table with at least:
          id              (int)
          agent           (text)    -- e.g. 'fileops'
          status          (text)    -- 'queued' | 'running' | 'done' | 'error'
          payload         (text)    -- JSON string
          result          (text)    -- optional
          error_message   (text)    -- optional

    WARNING:
      This script can change files and run commands on your machine.
      Keep Supabase keys and table access locked down.
#>

param(
    [int]$PollSeconds = 15
)

# -------------------------
#  CONFIG
# -------------------------

# Supabase config from env
$SupabaseUrl        = $env:SUPABASE_URL
$SupabaseServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $SupabaseUrl -or -not $SupabaseServiceKey) {
    Write-Host "[FileOpsWorker] ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set in environment." -ForegroundColor Red
    Write-Host "Set them in your .env and load via Jarvis-LoadEnv.ps1 before running."
    exit 1
}

# Table & column names (adjust to your real schema if needed)
$CommandTable  = "az_commands"
$AgentField    = "agent"
$StatusField   = "status"
$PayloadField  = "payload"
$ResultField   = "result"        # optional; worker will PATCH if exists
$ErrorField    = "error_message" # optional

# Agent identity
$AgentCode     = "fileops"       # value in 'agent' column for this worker

# Status values
$StatusQueued  = "queued"
$StatusRunning = "running"
$StatusDone    = "done"
$StatusError   = "error"

# Allowed root paths for file operations (SAFETY)
# Only paths that start with ANY of these prefixes will be touched.
$AllowedRoots = @(
    "F:\AION-ZERO",
    "F:\Jarvis-Desktop-Agent",
    "F:\Jarvis-LocalOps",
    "F:\ReachX-AI",
    "C:\Users\ICL  ZAMBIA\Desktop"
)

# Optional log file
$LogFile = "F:\AION-ZERO\logs\Jarvis-FileOpsWorker.log"

# -------------------------
#  HELPER FUNCTIONS
# -------------------------

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] [$Level] $Message"
    Write-Host $line
    if ($LogFile) {
        try {
            $line | Out-File -FilePath $LogFile -Append -Encoding UTF8
        } catch {
            Write-Host "[FileOpsWorker] Failed to write log file: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

function Test-PathAllowed {
    param(
        [string]$Path
    )
    if (-not $Path) { return $false }
    $normalized = [System.IO.Path]::GetFullPath($Path)
    foreach ($root in $AllowedRoots) {
        $rootNormalized = [System.IO.Path]::GetFullPath($root)
        if ($normalized.StartsWith($rootNormalized, [System.StringComparison]::InvariantCultureIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Invoke-SupabaseGet {
    param(
        [string]$RelativePath,
        [hashtable]$QueryParams
    )

    # Build URL with query parameters
    $uriBuilder = [System.UriBuilder]::new("$SupabaseUrl/$RelativePath")
    if ($QueryParams -and $QueryParams.Count -gt 0) {
        $pairs = @()
        foreach ($k in $QueryParams.Keys) {
            $v = [uri]::EscapeDataString([string]$QueryParams[$k])
            $pairs += "$k=$v"
        }
        $uriBuilder.Query = ($pairs -join "&")
    }

    $headers = @{
        "apikey"        = $SupabaseServiceKey
        "Authorization" = "Bearer $SupabaseServiceKey"
    }

    try {
        return Invoke-RestMethod -Method Get -Uri $uriBuilder.Uri.AbsoluteUri -Headers $headers
    } catch {
        Write-Log "Supabase GET failed: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Invoke-SupabasePatch {
    param(
        [string]$RelativePath,
        [hashtable]$Filters,
        [hashtable]$Body
    )

    $uriBuilder = [System.UriBuilder]::new("$SupabaseUrl/$RelativePath")
    if ($Filters -and $Filters.Count -gt 0) {
        $pairs = @()
        foreach ($k in $Filters.Keys) {
            $v = [uri]::EscapeDataString([string]$Filters[$k])
            $pairs += "$k=$v"
        }
        $uriBuilder.Query = ($pairs -join "&")
    }

    $headers = @{
        "apikey"        = $SupabaseServiceKey
        "Authorization" = "Bearer $SupabaseServiceKey"
        "Content-Type"  = "application/json"
        "Prefer"        = "return=representation"
    }

    $json = ($Body | ConvertTo-Json -Depth 10)

    try {
        return Invoke-RestMethod -Method Patch -Uri $uriBuilder.Uri.AbsoluteUri -Headers $headers -Body $json
    } catch {
        Write-Log "Supabase PATCH failed: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Get-NextCommand {
    # Select first queued command for this agent, oldest first
    $relativePath = "rest/v1/$CommandTable"
    $query = @{
        "select"        = "*"
        "$AgentField"   = "eq.$AgentCode"
        "$StatusField"  = "eq.$StatusQueued"
        "order"         = "created_at.asc"
        "limit"         = "1"
    }

    $result = Invoke-SupabaseGet -RelativePath $relativePath -QueryParams $query
    if ($null -eq $result) { return $null }

    # Supabase returns array of PSCustomObject
    if ($result -is [System.Array]) {
        if ($result.Count -gt 0) {
            return $result[0]
        } else {
            return $null
        }
    } elseif ($result) {
        return $result
    }

    return $null
}

function Set-CommandStatus {
    param(
        [int]$Id,
        [string]$Status,
        [string]$ResultText = $null,
        [string]$ErrorText  = $null
    )

    $body = @{}
    $body[$StatusField] = $Status

    if ($ResultField -and $ResultText) {
        $body[$ResultField] = $ResultText
    }
    if ($ErrorField -and $ErrorText) {
        $body[$ErrorField] = $ErrorText
    }

    $filters = @{ "id" = "eq.$Id" }
    $relativePath = "rest/v1/$CommandTable"
    $null = Invoke-SupabasePatch -RelativePath $relativePath -Filters $filters -Body $body
}

function Handle-WriteFile {
    param(
        [int]$Id,
        [hashtable]$Payload
    )

    $path     = $Payload.path
    $content  = $Payload.content
    $encoding = $Payload.encoding
    if (-not $encoding) { $encoding = "utf8" }

    if (-not (Test-PathAllowed -Path $path)) {
        $msg = "Path '$path' is not in allowed roots. Refusing write."
        Write-Log $msg "ERROR"
        Set-CommandStatus -Id $Id -Status $StatusError -ErrorText $msg
        return
    }

    try {
        $dir = Split-Path -Path $path -Parent
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        Set-Content -Path $path -Value $content -Encoding $encoding
        $msg = "write_file OK -> $path"
        Write-Log $msg "INFO"
        Set-CommandStatus -Id $Id -Status $StatusDone -ResultText $msg
    } catch {
        $msg = "write_file FAILED -> $path : $($_.Exception.Message)"
        Write-Log $msg "ERROR"
        Set-CommandStatus -Id $Id -Status $StatusError -ErrorText $msg
    }
}

function Handle-AppendFile {
    param(
        [int]$Id,
        [hashtable]$Payload
    )

    $path    = $Payload.path
    $content = $Payload.content

    if (-not (Test-PathAllowed -Path $path)) {
        $msg = "Path '$path' is not in allowed roots. Refusing append."
        Write-Log $msg "ERROR"
        Set-CommandStatus -Id $Id -Status $StatusError -ErrorText $msg
        return
    }

    try {
        $dir = Split-Path -Path $path -Parent
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        Add-Content -Path $path -Value $content -Encoding UTF8
        $msg = "append_file OK -> $path"
        Write-Log $msg "INFO"
        Set-CommandStatus -Id $Id -Status $StatusDone -ResultText $msg
    } catch {
        $msg = "append_file FAILED -> $path : $($_.Exception.Message)"
        Write-Log $msg "ERROR"
        Set-CommandStatus -Id $Id -Status $StatusError -ErrorText $msg
    }
}

function Handle-RunShell {
    param(
        [int]$Id,
        [hashtable]$Payload
    )

    $command     = $Payload.command
    $workingDir  = $Payload.working_dir
    $timeoutSec  = $Payload.timeout_sec
    if (-not $timeoutSec -or $timeoutSec -le 0) { $timeoutSec = 600 }

    if ($workingDir -and -not (Test-PathAllowed -Path $workingDir)) {
        $msg = "Working directory '$workingDir' not in allowed roots. Refusing run_shell."
        Write-Log $msg "ERROR"
        Set-CommandStatus -Id $Id -Status $StatusError -ErrorText $msg
        return
    }

    if (-not $command) {
        $msg = "run_shell payload missing 'command'."
        Write-Log $msg "ERROR"
        Set-CommandStatus -Id $Id -Status $StatusError -ErrorText $msg
        return
    }

    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName  = "powershell.exe"
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `$ErrorActionPreference='Stop'; $command"
        if ($workingDir) {
            $psi.WorkingDirectory = $workingDir
        }
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true
        $psi.UseShellExecute        = $false
        $psi.CreateNoWindow         = $true

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi

        [void]$proc.Start()

        if (-not $proc.WaitForExit($timeoutSec * 1000)) {
            $proc.Kill()
            $msg = "run_shell TIMEOUT after $timeoutSec sec. Command: $command"
            Write-Log $msg "ERROR"
            Set-CommandStatus -Id $Id -Status $StatusError -ErrorText $msg
            return
        }

        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $exitCode = $proc.ExitCode

        $resultText = "exit=$exitCode`nSTDOUT:`n$stdout`nSTDERR:`n$stderr"

        if ($exitCode -eq 0) {
            Write-Log "run_shell OK. Command: $command" "INFO"
            Set-CommandStatus -Id $Id -Status $StatusDone -ResultText $resultText
        } else {
            Write-Log "run_shell FAILED exit=$exitCode. Command: $command" "ERROR"
            Set-CommandStatus -Id $Id -Status $StatusError -ErrorText $resultText
        }
    } catch {
        $msg = "run_shell EXCEPTION: $($_.Exception.Message)"
        Write-Log $msg "ERROR"
        Set-CommandStatus -Id $Id -Status $StatusError -ErrorText $msg
    }
}

function Handle-Command {
    param(
        $Cmd   # PSCustomObject from Supabase; do NOT force hashtable here
    )

    $id = [int]$Cmd.id
    $payloadRaw = $Cmd.$PayloadField

    if (-not $payloadRaw) {
        $msg = "Command id=$($id) has empty payload."
        Write-Log $msg "ERROR"
        Set-CommandStatus -Id $id -Status $StatusError -ErrorText $msg
        return
    }

    try {
        $payload = $payloadRaw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        $msg = "Failed to parse payload JSON for id=$($id): $($_.Exception.Message)"
        Write-Log $msg "ERROR"
        Set-CommandStatus -Id $id -Status $StatusError -ErrorText $msg
        return
    }

    # Convert PSObject from ConvertFrom-Json to hashtable for handlers
    $payloadHashtable = @{}
    foreach ($prop in $payload.PSObject.Properties) {
        $payloadHashtable[$prop.Name] = $prop.Value
    }

    # Mark as running
    Set-CommandStatus -Id $id -Status $StatusRunning

    $kind = $payloadHashtable.kind
    if (-not $kind) {
        $msg = "Payload for id=$($id) missing 'kind'."
        Write-Log $msg "ERROR"
        Set-CommandStatus -Id $id -Status $StatusError -ErrorText $msg
        return
    }

    Write-Log "Processing command id=$($id) kind='$kind'" "INFO"

    switch ($kind) {
        "write_file"   { Handle-WriteFile  -Id $id -Payload $payloadHashtable }
        "append_file"  { Handle-AppendFile -Id $id -Payload $payloadHashtable }
        "run_shell"    { Handle-RunShell   -Id $id -Payload $payloadHashtable }
        default {
            $msg = "Unknown kind='$kind' for id=$($id)."
            Write-Log $msg "ERROR"
            Set-CommandStatus -Id $id -Status $StatusError -ErrorText $msg
        }
    }
}

# -------------------------
#  MAIN LOOP
# -------------------------

Write-Log "=== Jarvis FileOps Worker starting. Agent='$AgentCode', Poll=$PollSeconds sec ==="

while ($true) {
    try {
        $cmd = Get-NextCommand
        if ($null -eq $cmd) {
            Start-Sleep -Seconds $PollSeconds
            continue
        }

        Handle-Command -Cmd $cmd

    } catch {
        Write-Log "Top-level loop exception: $($_.Exception.Message)" "ERROR"
        # Small delay to avoid busy-looping on fatal errors
        Start-Sleep -Seconds $PollSeconds
    }
}
