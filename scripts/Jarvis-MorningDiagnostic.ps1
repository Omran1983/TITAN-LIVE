param()

$ErrorActionPreference = 'Stop'

# --- helpers ----------------------------------------------------
function Write-Title {
    param([string]$Text)
    Write-Host ""
    Write-Host "=== $Text ===" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Text)
    Write-Host ("[OK]  {0}" -f $Text) -ForegroundColor Green
}

function Write-Warn {
    param([string]$Text)
    Write-Host ("[WARN] {0}" -f $Text) -ForegroundColor Yellow
}

function Write-ErrLine {
    param([string]$Text)
    Write-Host ("[ERR] {0}" -f $Text) -ForegroundColor Red
}

# --- locate script dir + load env ------------------------------
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$loadEnvPath = Join-Path $ScriptDir 'Jarvis-LoadEnv.ps1'

if (Test-Path $loadEnvPath) {
    & $loadEnvPath
} else {
    Write-Warn "Jarvis-LoadEnv.ps1 not found at $loadEnvPath – using current env only."
}

# --- env + Supabase headers ------------------------------------
$SupabaseUrl = $env:SUPABASE_URL
$SupabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY

$supabaseReady = $true
if (-not $SupabaseUrl) {
    Write-ErrLine "SUPABASE_URL not set in environment."
    $supabaseReady = $false
}
if (-not $SupabaseKey) {
    Write-ErrLine "SUPABASE_SERVICE_ROLE_KEY not set in environment."
    $supabaseReady = $false
}

if ($supabaseReady) {
    $headers = @{
        apikey         = $SupabaseKey
        Authorization  = "Bearer $SupabaseKey"
        Accept         = "application/json"
        "Content-Type" = "application/json"
    }
}

# --- small helper to safely call Supabase ----------------------
function Invoke-Supa {
    param(
        [string]$Path,  # e.g. "/rest/v1/az_commands?..."
        [string]$Method = 'Get',
        $Body = $null
    )

    if (-not $script:supabaseReady) {
        return $null
    }

    $url = "$($script:SupabaseUrl)$Path"

    try {
        if ($Body -ne $null) {
            $json = $Body | ConvertTo-Json -Depth 10
            return Invoke-RestMethod -Method $Method -Uri $url -Headers $script:headers -Body $json
        } else {
            return Invoke-RestMethod -Method $Method -Uri $url -Headers $script:headers
        }
    }
    catch {
        Write-Warn ("Supabase call failed for {0}: {1}" -f $Path, $_.Exception.Message)
        return $null
    }
}

# --- HTTP endpoint tester --------------------------------------
function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url
    )
    try {
        $resp = Invoke-RestMethod -Method Get -Uri $Url -TimeoutSec 3
        $status = $null
        if ($resp -and $resp.PSObject.Properties.Name -contains 'status') {
            $status = $resp.status
        }
        if ($status) {
            Write-Ok "$Name → ONLINE (status=$status)"
        } else {
            Write-Ok "$Name → ONLINE (no explicit status field)"
        }
    }
    catch {
        Write-Warn "$Name → OFFLINE ($($_.Exception.Message))"
    }
}

Write-Host ""
Write-Host "=== Jarvis / AION-ZERO Morning Diagnostic ===" -ForegroundColor Cyan
Write-Host ("Time: {0}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor DarkGray

# ----------------------------------------------------------------
# 1) HTTP Health Endpoints
# ----------------------------------------------------------------
Write-Title "HTTP Health Endpoints"

Test-Endpoint -Name "CommandsApi 5051" -Url "http://127.0.0.1:5051/health"
Test-Endpoint -Name "AION-ZERO Health 5052" -Url "http://127.0.0.1:5052/health"

# ----------------------------------------------------------------
# 2) Supabase: Health Snapshots
# ----------------------------------------------------------------
Write-Title "Supabase: Health Snapshots"

if ($supabaseReady) {
    $resp = Invoke-Supa -Path "/rest/v1/az_health_snapshots?select=*&order=id.desc`&limit=1"
    $snap = @($resp) | Select-Object -First 1
    if ($snap) {
        $project    = $snap.project
        $status     = $snap.status
        $queue      = $snap.queue_depth
        $errors     = $snap.error_count
        $created_at = $snap.created_at

        Write-Ok ("Last snapshot → project={0}, status={1}, queue={2}, errors={3}, at={4}" -f `
            $project, $status, $queue, $errors, $created_at)
    } else {
        Write-Warn "No az_health_snapshots rows found."
    }
} else {
    Write-Warn "Skipping health snapshots (Supabase env not ready)."
}

# ----------------------------------------------------------------
# 3) Supabase: Command Queue
# ----------------------------------------------------------------
Write-Title "Supabase: Command Queue"

if ($supabaseReady) {
    $resp = Invoke-Supa -Path "/rest/v1/az_commands?select=id,project,agent,action,status`&status=eq.queued`&order=id.asc"
    $queued = @($resp)
    $count  = $queued.Count

    Write-Ok ("Queued commands: {0}" -f $count)

    if ($count -gt 0) {
        $queued |
            Select-Object -First 10 id, project, agent, action, status |
            Format-Table -AutoSize
    }
} else {
    Write-Warn "Skipping command queue (Supabase env not ready)."
}

# ----------------------------------------------------------------
# 4) Supabase: Agents Registry
# ----------------------------------------------------------------
Write-Title "Supabase: Agents Registry"

if ($supabaseReady) {
    $resp = Invoke-Supa -Path "/rest/v1/az_agents?select=id,code,role,status,is_enabled`&order=code.asc"
    if ($resp) {
        @($resp) |
            Select-Object id, code, role, status, is_enabled |
            Format-Table -AutoSize
    } else {
        Write-Warn "No az_agents rows returned (or table not yet wired)."
    }
} else {
    Write-Warn "Skipping agents registry (Supabase env not ready)."
}

# ----------------------------------------------------------------
# 5) Supabase: Recent Errors (az_commands)
# ----------------------------------------------------------------
Write-Title "Supabase: Recent Errors (az_commands)"

if ($supabaseReady) {
    $resp = Invoke-Supa -Path "/rest/v1/az_commands?select=id,project,agent,action,status,error_message,updated_at`&status=eq.error`&order=updated_at.desc`&limit=5"
    $errs = @($resp)
    if ($errs.Count -gt 0) {
        $errs |
            Select-Object id, project, agent, action, status, updated_at, error_message |
            Format-Table -AutoSize
    } else {
        Write-Ok "No recent error commands."
    }
} else {
    Write-Warn "Skipping error list (Supabase env not ready)."
}

# ----------------------------------------------------------------
# 6) Windows Scheduled Tasks (Jarvis-*)
# ----------------------------------------------------------------
Write-Title "Windows Scheduled Tasks (Jarvis-*)"

try {
    $tasks = Get-ScheduledTask -TaskName "Jarvis-*" -ErrorAction SilentlyContinue
    if ($tasks) {
        $tasks |
            Sort-Object TaskName |
            Select-Object TaskName, State, LastRunTime, NextRunTime |
            Format-Table -AutoSize
    } else {
        Write-Warn "No scheduled tasks found matching 'Jarvis-*'."
    }
}
catch {
    Write-Warn ("Failed to read scheduled tasks: {0}" -f $_.Exception.Message)
}

# ----------------------------------------------------------------
# 7) PowerShell Processes
# ----------------------------------------------------------------
Write-Title "PowerShell Processes"

try {
    $psProcs = Get-Process -Name "powershell", "pwsh" -ErrorAction SilentlyContinue
    if ($psProcs) {
        $psProcs |
            Sort-Object StartTime |
            Select-Object Id, ProcessName, CPU, StartTime |
            Format-Table -AutoSize
    } else {
        Write-Warn "No PowerShell processes detected (script may be running inside one)."
    }
}
catch {
    Write-Warn ("Failed to inspect PowerShell processes: {0}" -f $_.Exception.Message)
}

# ----------------------------------------------------------------
# 8) Summary
# ----------------------------------------------------------------
Write-Title "Summary"

if ($supabaseReady) {
    Write-Ok "Supabase env loaded."
} else {
    Write-ErrLine "Supabase env NOT fully loaded – fix SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY."
}

Write-Ok "Morning Diagnostic complete."
Write-Host ""
