param(
    [string]$Environment       = "dev",
    [int]$PollIntervalSeconds  = 20
)

Write-Host "=== ReachX Worker Agent starting (env=$Environment) ===" -ForegroundColor Cyan

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Error "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set."
    exit 1
}

$baseUrl = $env:SUPABASE_URL.Trim()
$baseUrl = $baseUrl -replace "/+$",""
$apiKey  = $env:SUPABASE_SERVICE_ROLE_KEY

$workerName = $env:COMPUTERNAME

$jobsUrl = "$baseUrl/rest/v1/system_remote_jobs"

$headers = @{
    "apikey"        = $apiKey
    "Authorization" = "Bearer $apiKey"
    "Content-Type"  = "application/json"
}

function Get-NextJob {
    # Build URI safely
    $uri = $jobsUrl + "?environment=eq." + $Environment +
        "&machine_name_target=eq." + $workerName +
        "&status=eq.queued&order=created_at.asc&limit=1"

    Write-Host "DEBUG jobs URI: [$uri]" -ForegroundColor DarkGray

    try {
        $jobs = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction Stop
        if ($jobs -and $jobs.Count -gt 0) {
            return $jobs[0]
        }
        return $null
    } catch {
        Write-Error "Error polling jobs: $_"
        return $null
    }
}

function Update-JobStatus {
    param(
        [long]$JobId,
        [string]$Status,
        [string]$StdoutSnippet = $null,
        [string]$LastError     = $null,
        [bool]$SetStarted      = $false,
        [bool]$SetFinished     = $false
    )

    $patch = @{}
    $patch["status"] = $Status

    if ($StdoutSnippet) { $patch["stdout_snippet"] = $StdoutSnippet }
    if ($LastError)     { $patch["last_error"]     = $LastError }

    $nowIso = (Get-Date).ToString("o")
    if ($SetStarted)  { $patch["started_at"]  = $nowIso }
    if ($SetFinished) { $patch["finished_at"] = $nowIso }

    $body = ($patch | ConvertTo-Json -Depth 5)

    # IMPORTANT: build URL via concatenation, no interpolation
    $uri = $jobsUrl + "?id=eq." + $JobId

    Write-Host "DEBUG update URI for job ${JobId}: [$uri]" -ForegroundColor DarkGray
    Write-Host "DEBUG patch body: $body" -ForegroundColor DarkGray

    $localHeaders = $headers.Clone()
    $localHeaders["Prefer"] = "return=representation"

    try {
        $resp = Invoke-RestMethod -Method Patch -Uri $uri -Headers $localHeaders -Body $body -ErrorAction Stop
        return $resp
    } catch {
        Write-Error "Failed to update job ${JobId}: $_"
    }
}

while ($true) {
    Write-Host "[$(Get-Date -Format 'u')] Checking for jobs for $workerName ..." -ForegroundColor DarkGray
    $job = Get-NextJob

    if (-not $job) {
        Start-Sleep -Seconds $PollIntervalSeconds
        continue
    }

    $jobId   = $job.id
    $cmdType = $job.command_type
    $cmdText = $job.command_text

    Write-Host "Found job id=$jobId type=$cmdType" -ForegroundColor Yellow

    # Mark as running
    Update-JobStatus -JobId $jobId -Status "running" -SetStarted $true | Out-Null

    # Execute command
    $stdout  = ""
    $stderr  = ""
    $success = $false

    try {
        if ($cmdType -eq "powershell") {
            $ps = [PowerShell]::Create().AddScript($cmdText)
            $ps.Streams.Error.Clear()

            $result = $ps.Invoke()

            if ($ps.Streams.Error.Count -gt 0) {
                $stderr = ($ps.Streams.Error | ForEach-Object { $_.ToString() }) -join "`n"
            }

            if ($result) {
                $stdout = ($result | ForEach-Object { $_.ToString() }) -join "`n"
            }

            if (-not $stderr) {
                $success = $true
            }
        } else {
            $stderr = "Unsupported command_type: $cmdType"
        }
    } catch {
        $stderr = $_.ToString()
    }

    $snippet = if ($stdout.Length -gt 400) { $stdout.Substring(0, 400) } else { $stdout }
    $errSnip = if ($stderr.Length -gt 400) { $stderr.Substring(0, 400) } else { $stderr }

    if ($success) {
        Write-Host "Job $jobId completed successfully." -ForegroundColor Green
        Update-JobStatus -JobId $jobId -Status "success" -StdoutSnippet $snippet -SetFinished $true | Out-Null
    } else {
        Write-Host "Job $jobId failed." -ForegroundColor Red
        Update-JobStatus -JobId $jobId -Status "failed" -StdoutSnippet $snippet -LastError $errSnip -SetFinished $true | Out-Null
    }

    # Short pause before checking again
    Start-Sleep -Seconds 2
}
