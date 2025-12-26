<# 
    F:\AION-ZERO\scripts\Jarvis-AutoHealAgent.ps1

    Jarvis AutoHeal Agent – Auto-discovery (Option C)

    - Loads env from .env-main via Use-ProjectEnv.ps1 if present
    - Uses SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY
    - Reads column metadata from public.autoheal_columns_view
      (view over information_schema.columns created in Supabase)
    - Detects "job-like" tables (status / state columns)
    - For each such table, fetches rows with status in (error, failed, timeout)
    - Logs compact summary into F:\AION-ZERO\logs\autoheal.log
    - Special case: for proxy_events, auto-archives old error events
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

# ---------- Paths / logging ----------

$projectRoot = "F:\AION-ZERO"
$logDir     = Join-Path $projectRoot "logs"
$logPath    = Join-Path $logDir "autoheal.log"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-AHLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logPath -Append -Encoding UTF8
}

Write-AHLog "===== Jarvis AutoHeal Agent START (auto-discovery) ====="

# ---------- Load env (.env-main) if available ----------

$envFile   = Join-Path $projectRoot ".env-main"
$envLoader = Join-Path $projectRoot "scripts\Use-ProjectEnv.ps1"

if (Test-Path $envFile) {
    if (Test-Path $envLoader) {
        try {
            Write-AHLog "Loading environment from $envFile via Use-ProjectEnv.ps1"
            . $envLoader -EnvFilePath $envFile
        } catch {
            Write-AHLog "WARNING: Failed to load env from .env-main - $($_.Exception.Message)"
        }
    } else {
        Write-AHLog "NOTE: Env loader script not found at $envLoader; using current process env."
    }
} else {
    Write-AHLog "NOTE: .env-main not found at $envFile; using current process env."
}

# ---------- Supabase config ----------

$supabaseUrl        = $env:SUPABASE_URL
$supabaseServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $supabaseUrl -or -not $supabaseServiceKey) {
    Write-AHLog "ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set in environment."
    Write-AHLog "      Set them in .env-main or system env and re-run."
    Write-AHLog "===== Jarvis AutoHeal Agent END (config error) ====="
    exit 1
}

$supabaseUrl = $supabaseUrl.TrimEnd("/")

$sbHeaders = @{
    "apikey"        = $supabaseServiceKey
    "Authorization" = "Bearer $supabaseServiceKey"
    "Content-Type"  = "application/json"
    "Accept"        = "application/json"
    "Prefer"        = "return=representation"
}

# ---------- Helper: safe REST call ----------

function Invoke-SbRest {
    param(
        [Parameter(Mandatory=$true)][string]$Uri,
        [ValidateSet("GET","POST","PATCH","DELETE")][string]$Method = "GET",
        [object]$Body = $null
    )

    try {
        if ($Body -ne $null) {
            $json = $Body | ConvertTo-Json -Depth 10
            return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $sbHeaders -Body $json
        } else {
            return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $sbHeaders
        }
    } catch {
        Write-AHLog "ERROR: REST $Method $Uri -> $($_.Exception.Message)"
        return $null
    }
}

# ---------- Special: healing logic for proxy_events ----------

function Heal-ProxyEvents {
    Write-AHLog "[proxy_events] Auto-heal: archiving all current error events..."

    # PATCH /rest/v1/proxy_events?status=eq.error
    $uri  = "{0}/rest/v1/proxy_events?status=eq.error" -f $supabaseUrl
    $body = @{ status = "archived_error" }

    $resp = Invoke-SbRest -Uri $uri -Method "PATCH" -Body $body

    $count = 0
    if ($resp -is [System.Array]) {
        $count = $resp.Count
    } elseif ($resp) {
        $count = 1
    }

    Write-AHLog "[proxy_events] Auto-heal: archived $count row(s) (status=error)."
}

# ---------- Step 1: discover candidate tables via autoheal_columns_view ----------

Write-AHLog "Discovering job-like tables from autoheal_columns_view..."

# REST view you created in Supabase
$columnsUri = "$supabaseUrl/rest/v1/autoheal_columns_view?select=table_name,column_name&limit=10000"

$cols = Invoke-SbRest -Uri $columnsUri -Method "GET"

if (-not $cols) {
    Write-AHLog "ERROR: Could not fetch autoheal_columns_view. Auto-discovery aborted."
    Write-AHLog "===== Jarvis AutoHeal Agent END (discovery failed) ====="
    exit 0
}

# Filter for columns that look like status / state fields
$interestingCols = $cols | Where-Object {
    $name = $_.column_name.ToLower()
    $name -eq "status"      -or
    $name -like "*_status"  -or
    $name -eq "state"       -or
    $name -eq "job_status"
}

if (-not $interestingCols -or $interestingCols.Count -eq 0) {
    Write-AHLog "No job-like tables detected (no status/state columns in public schema)."
    Write-AHLog "===== Jarvis AutoHeal Agent END (nothing to scan) ====="
    exit 0
}

# Group by table_name to get candidates
$candidateGroups = $interestingCols | Group-Object table_name
$candidateTableNames = $candidateGroups | ForEach-Object { $_.Name }

Write-AHLog ("Detected job-like candidate tables: " + ($candidateTableNames -join ", "))

# Build a quick map of columns per table for later lookup
$tableColumnsMap = @{}
foreach ($c in $cols) {
    $t = $c.table_name
    if (-not $tableColumnsMap.ContainsKey($t)) {
        $tableColumnsMap[$t] = @()
    }
    $tableColumnsMap[$t] += $c.column_name
}

# ---------- Step 2: scan each candidate table for failed rows ----------

# Status values we consider as "failed"
$failedStates = @("error", "failed", "timeout")

foreach ($group in $candidateGroups) {
    $tableName    = $group.Name
    $colsForTable = $tableColumnsMap[$tableName]

    # Pick best status column
    $statusCol = $group.Group |
        Sort-Object column_name | # deterministic
        ForEach-Object { $_.column_name } |
        Where-Object {
            $n = $_.ToLower()
            $n -eq "status" -or
            $n -like "*_status" -or
            $n -eq "state" -or
            $n -eq "job_status"
        } |
        Select-Object -First 1

    if (-not $statusCol) {
        Write-AHLog "[$tableName] Skipping: no suitable status column."
        continue
    }

    # Look for useful error / attempts columns if available
    $errorCol = $colsForTable | Where-Object {
        $n = $_.ToLower()
        $n -eq "error" -or
        $n -eq "error_message" -or
        $n -eq "last_error" -or
        $n -eq "failure_reason"
    } | Select-Object -First 1

    $attemptsCol = $colsForTable | Where-Object {
        $n = $_.ToLower()
        $n -eq "attempts" -or
        $n -eq "retries" -or
        $n -eq "retry_count"
    } | Select-Object -First 1

    Write-AHLog "[$tableName] Scanning using status column '$statusCol'..."

    # Build filter: statusCol in (error,failed,timeout)
    $stateList = ($failedStates -join ",")
    $scanUri   = "{0}/rest/v1/{1}?select=*&{2}=in.({3})" -f $supabaseUrl, $tableName, $statusCol, $stateList

    $rows = Invoke-SbRest -Uri $scanUri -Method "GET"
    if (-not $rows) {
        Write-AHLog "[$tableName] No data returned or error while fetching."
        continue
    }

    # Force to array
    $rowsArray = @($rows)
    if ($rowsArray.Count -eq 0) {
        Write-AHLog "[$tableName] No failed rows found."
        continue
    }

    Write-AHLog "[$tableName] Found $($rowsArray.Count) failed row(s)."

    foreach ($row in $rowsArray) {
        # Try to identify key fields
        $props = $row.PSObject.Properties.Name

        $idVal = if ($props -contains "id") { $row.id } elseif ($props -contains "job_id") { $row.job_id } else { "<no-id>" }
        $statusVal = $null
        try { $statusVal = $row.$statusCol } catch { $statusVal = "<n/a>" }

        $errorVal = $null
        if ($errorCol) {
            try { $errorVal = $row.$errorCol } catch { $errorVal = "<n/a>" }
        }

        $attemptsVal = $null
        if ($attemptsCol) {
            try { $attemptsVal = $row.$attemptsCol } catch { $attemptsVal = "<n/a>" }
        }

        $summary = "[$tableName] FAILED row id=$idVal status=$statusVal"
        if ($attemptsCol) { $summary += " attempts=$attemptsVal" }
        if ($errorCol -and $errorVal) { 
            $errStr = [string]$errorVal
            if ($errStr.Length -gt 200) { $errStr = $errStr.Substring(0,200) + "..." }
            $summary += " error=""$errStr"""
        }

        Write-AHLog $summary
    }
}

# ---------- Step 3: call healers ----------

try {
    Heal-ProxyEvents
} catch {
    Write-AHLog "[proxy_events] Auto-heal failed: $($_.Exception.Message)"
}

# ---------- Step 4: write heartbeat to jarvis_healthchecks ----------

try {
    # Count of failed rows we saw this run (for now, 0 because we only log them;
    # later we can increment this as we detect them).
    $failedCount = 0

    $hbUri = "{0}/rest/v1/jarvis_healthchecks" -f $supabaseUrl
    $hbBody = @{
        source      = "autoheal"
        status      = "ok"
        details     = "AutoHeal scan complete; see autoheal.log for detail."
        failed_jobs = $failedCount
    }

    $hbResp = Invoke-SbRest -Uri $hbUri -Method "POST" -Body $hbBody
    if ($hbResp) {
        Write-AHLog "Heartbeat inserted into jarvis_healthchecks."
    } else {
        Write-AHLog "WARNING: Failed to insert heartbeat into jarvis_healthchecks."
    }
} catch {
    Write-AHLog "ERROR: Heartbeat insert failed: $($_.Exception.Message)"
}

Write-AHLog "===== Jarvis AutoHeal Agent END (scan complete) ====="
exit 0
