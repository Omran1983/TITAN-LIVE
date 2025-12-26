param(
    [int]$CommandId = 0,
    [switch]$SingleRun
)

$ErrorActionPreference = "Stop"

if (-not $SingleRun) {
    Write-Host "`n=== Jarvis AutoSQL Worker ==="
    Write-Host "Polling every 10 seconds..."
    Write-Host "Ctrl + C to stop.`n"
}

# Load environment variables
. "F:\AION-ZERO\scripts\Jarvis-LoadEnv.ps1"

function Process-SqlQueueItem {
    param([PSCustomObject]$cmd, [string]$sbUrl, [string]$sbKey, [hashtable]$headers)

    $id = $cmd.id
    $sqlInstruction = $cmd.instruction

    Write-Host "`n[AutoSQL] Found SQL command #$id" -ForegroundColor Cyan

    # Mark in progress
    $body = @{ status = "in_progress" } | ConvertTo-Json
    Invoke-RestMethod -Method Patch -Uri "$sbUrl/rest/v1/az_commands?id=eq.$id" -Headers $headers -Body $body

    # Execute SQL via Python runner
    $pythonExe = "python"
    $scriptPath = "F:\AION-ZERO\src\jarvis_control\jarvis-auto-sql.py"

    Write-Host "Running AutoSQL Python..." -ForegroundColor DarkGray
    $raw = & $pythonExe $scriptPath "$sqlInstruction" 2>&1

    # Extract SQL after marker
    $lines = $raw -split "`r?`n"
    $startIdx = $lines.IndexOf("=== SQL ===")

    if ($startIdx -lt 0) {
        Write-Host "[AutoSQL ERROR] No SQL marker found." -ForegroundColor Red
        return
    }

    $sqlLines = $lines[($startIdx + 1)..($lines.Length - 1)]
    $finalSql = ($sqlLines -join "`n").Trim()

    # Patch row with generated SQL
    $patchBody = @{
        generated_sql = $finalSql
        auto_sql_raw  = $raw
        status        = "sql_ready"
        updated_at    = (Get-Date).ToUniversalTime().ToString("o")
    } | ConvertTo-Json -Depth 5

    Invoke-RestMethod -Method Patch -Uri "$sbUrl/rest/v1/az_commands?id=eq.$id" -Headers $headers -Body $patchBody

    Write-Host "[AutoSQL] SQL command #$id complete." -ForegroundColor Green
}

while ($true) {
    try {
        # Resolve Supabase URL + key
        $sbUrl = $env:JARVIS_SUPABASE_URL
        if (-not $sbUrl) { $sbUrl = $env:SUPABASE_URL }

        $sbKey = $env:JARVIS_SUPABASE_SERVICE_ROLE
        if (-not $sbKey) { $sbKey = $env:SUPABASE_SERVICE_KEY }

        if (-not $sbUrl -or -not $sbKey) {
            Write-Host "ERROR: Supabase env not loaded." -ForegroundColor Red
            if ($SingleRun) { exit 1 }
            Start-Sleep -Seconds 10
            continue
        }

        $headers = @{
            apikey         = $sbKey
            Authorization  = "Bearer $sbKey"
            Accept         = "application/json"
            "Content-Type" = "application/json"
        }

        # Single Run Logic
        if ($SingleRun -and $CommandId -gt 0) {
            $url = "$sbUrl/rest/v1/az_commands?select=*&id=eq.$CommandId"
            $cmd = Invoke-RestMethod -Method Get -Uri $url -Headers $headers
            if ($cmd.Count -gt 0) {
                Process-SqlQueueItem -cmd $cmd[0] -sbUrl $sbUrl -sbKey $sbKey -headers $headers
            }
            else {
                Write-Warning "Command #$CommandId not found."
            }
            break # Exit loop
        }

        # Polling Logic
        $url = "$sbUrl/rest/v1/az_commands?select=*&action=eq.sql&status=eq.queued&limit=1"
        $cmd = Invoke-RestMethod -Method Get -Uri $url -Headers $headers

        if ($cmd.Count -gt 0) {
            Process-SqlQueueItem -cmd $cmd[0] -sbUrl $sbUrl -sbKey $sbKey -headers $headers
        }

    }
    catch {
        Write-Host "[AutoSQL ERROR] $_" -ForegroundColor Red
        if ($SingleRun) { exit 1 }
    }

    if ($SingleRun) { break }
    Start-Sleep -Seconds 10
}
