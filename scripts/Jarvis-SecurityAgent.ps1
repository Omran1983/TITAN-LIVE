# =====================================================================
# Jarvis-SecurityAgent.ps1
# v1.1 — Safe simulation worker for security_scan commands
#        (handles text JSON payload correctly)
# =====================================================================

$ErrorActionPreference = "Stop"

# -----------------------------------------------------------
# Load environment (Supabase keys, URLs)
# -----------------------------------------------------------
$root    = Split-Path $MyInvocation.MyCommand.Path -Parent
$loadEnv = Join-Path $root "Jarvis-LoadEnv.ps1"
. $loadEnv

$sbUrl  = $env:SUPABASE_URL
$sbKey  = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $sbUrl -or -not $sbKey) {
    Write-Host "ERROR: Missing Supabase environment variables."
    exit 1
}

Write-Host "=== Jarvis-SecurityAgent started at $(Get-Date -Format o) ==="

# -----------------------------------------------------------
# Helper: Perform Supabase queries
# -----------------------------------------------------------
function Invoke-Supa {
    param(
        [string]$Method,
        [string]$Endpoint,
        [object]$Body = $null
    )

    $headers = @{
        apikey         = $sbKey
        Authorization  = "Bearer $sbKey"
        Accept         = "application/json"
        "Content-Type" = "application/json"
    }

    $uri = "$sbUrl/rest/v1/$Endpoint"

    try {
        if ($Body) {
            $json = ($Body | ConvertTo-Json -Depth 10)
            return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -Body $json
        } else {
            return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers
        }
    }
    catch {
        Write-Host "Supabase request failed: $($_.Exception.Message)"
        throw
    }
}

# -----------------------------------------------------------
# Helper: normalize payload (text JSON → PSObject)
# -----------------------------------------------------------
function Get-NormalizedPayload {
    param(
        [object]$RawPayload
    )

    if ($null -eq $RawPayload) {
        return $null
    }

    # If it's already a PS object, just return
    if (-not ($RawPayload -is [string])) {
        return $RawPayload
    }

    # If it's a JSON string, parse it
    try {
        $parsed = $RawPayload | ConvertFrom-Json
        return $parsed
    }
    catch {
        Write-Host "ERROR: Failed to parse payload JSON: $($_.Exception.Message)"
        return $null
    }
}

# -----------------------------------------------------------
# Main loop — poll az_commands for security_scan
# -----------------------------------------------------------
while ($true) {

    $cmdId = $null

    try {
        Write-Host "[SecurityAgent] Polling for queued security_scan..."
        $cmd = Invoke-Supa "GET" "az_commands?select=*&status=eq.queued&action=eq.security_scan&order=id.asc&limit=1"

        if (-not $cmd) {
            Write-Host "[SecurityAgent] No queued security_scan found. Sleeping 5s..."
            Start-Sleep -Seconds 5
            continue
        }

        $command = $cmd[0]
        $cmdId   = $command.id

        Write-Host "`n--- Processing security_scan command #$cmdId ---"

        # Normalize payload (handles text column)
        $payload = Get-NormalizedPayload -RawPayload $command.payload

        if (-not $payload) {
            throw "Payload is null or could not be parsed from JSON."
        }

        # Mark as in_progress
        Invoke-Supa "PATCH" "az_commands?id=eq.$cmdId" @{
            status     = "in_progress"
            started_at = (Get-Date).ToString("o")
        }

        # ---------------------------------------------------
        # Payload validation
        # ---------------------------------------------------
        $targets = $payload.targets

        # Handle single string or array
        if ($targets -is [string]) {
            $targets = @($targets)
        }

        if (-not $targets -or $targets.Count -eq 0) {
            throw "No targets provided in payload."
        }

        $scanId = $payload.scan_id
        if (-not $scanId) {
            $scanId = "scan-$cmdId"
        }

        $customerId  = $payload.customer_id
        $scanProfile = $payload.scan_profile

        # Validate targets exist in whitelist table
        foreach ($t in $targets) {
            $encodedTarget = [System.Uri]::EscapeDataString($t)
            $rows = Invoke-Supa "GET" "az_security_targets?target_value=eq.$encodedTarget&status=eq.active"

            if (-not $rows) {
                throw "Target '$t' not allowed or not whitelisted in az_security_targets."
            }
        }

        # ---------------------------------------------------
        # Simulated scanning process
        # ---------------------------------------------------
        Write-Host "Simulating scan: $scanId"
        Write-Host "  Customer : $customerId"
        Write-Host "  Targets  : $($targets -join ', ')"
        Write-Host "  Profile  : $scanProfile"

        $startTime = Get-Date

        # Insert into az_security_scans
        Invoke-Supa "POST" "az_security_scans" @{
            scan_id     = $scanId
            customer_id = $customerId
            command_id  = $cmdId
            profile     = $scanProfile
            status      = "running"
            started_at  = $startTime.ToString("o")
        }

        # Fake runtime
        Start-Sleep -Seconds 3

        # ---------------------------------------------------
        # Insert fake findings (first target only, for demo)
        # ---------------------------------------------------
        $dummyFinding = @{
            scan_id     = $scanId
            severity    = "low"
            category    = "headers"
            cve_id      = $null
            endpoint    = $targets[0]
            description = "Simulated outdated security header"
            remediation = "Add X-Frame-Options and HSTS"
        }

        Invoke-Supa "POST" "az_security_findings" $dummyFinding

        # Finish scan
        $endTime = Get-Date

        Invoke-Supa "PATCH" "az_security_scans?scan_id=eq.$scanId" @{
            finished_at = $endTime.ToString("o")
            status      = "done"
            summary     = "Simulated scan completed successfully."
        }

        # Mark command done
        Invoke-Supa "PATCH" "az_commands?id=eq.$cmdId" @{
            status      = "done"
            finished_at = $endTime.ToString("o")
            result      = @{
                ok      = $true
                message = "Security scan $scanId completed"
            }
        }

        Write-Host "--- Scan complete #$cmdId ---`n"
    }
    catch {
        $err = $_.Exception.Message
        Write-Host "ERROR: $err"

        if ($cmdId) {
            try {
                Invoke-Supa "PATCH" "az_commands?id=eq.$cmdId" @{
                    status = "error"
                    result = @{
                        ok    = $false
                        error = $err
                    }
                }
            }
            catch {
                Write-Host "ERROR while marking command error: $($_.Exception.Message)"
            }
        }
    }

    Start-Sleep -Seconds 5
}
