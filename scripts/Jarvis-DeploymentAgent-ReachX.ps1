param(
    [string]$Once # if set to 'once', process one batch and exit
)

<#
.SYNOPSIS
    Jarvis DeploymentAgent for ReachX.

.DESCRIPTION
    - Watches az_commands for:
        project = 'reachx'
        action  = 'deploy'
        status  = 'queued'
    - For each command:
        * Marks it in_progress
        * (Stub) Creates az_project_runs row
        * Builds the ReachX project
        * Deploys via Cloudflare or Vercel (based on env)
        * Updates status + logs URL in az_project_runs (stub)
        * Marks az_commands as done or error

.REQUIRED ENV
    SUPABASE_URL
    SUPABASE_SERVICE_ROLE_KEY
    REACHX_REPO_PATH                # e.g. F:\ReachX-AI\infra\ReachX-Workers-UI-v1
    REACHX_DEPLOY_MODE              # 'cloudflare' or 'vercel'
    REACHX_DEPLOY_ENV               # default 'dev' if not set
    REACHX_CF_PROJECT (optional)    # for Cloudflare
    REACHX_VERCEL_PROJECT (optional)# for Vercel
#>

$ErrorActionPreference = 'Stop'

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "[$timestamp] [DeploymentAgent-ReachX] [$Level] $Message"
}

# Resolve script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load env (if you have a helper script)
$loadEnvPath = Join-Path $ScriptDir 'Jarvis-LoadEnv.ps1'
if (Test-Path $loadEnvPath) {
    & $loadEnvPath
}

# Read env vars
$SupabaseUrl  = $env:SUPABASE_URL
$SupabaseKey  = $env:SUPABASE_SERVICE_ROLE_KEY
$RepoPath     = $env:REACHX_REPO_PATH
$DeployMode   = $env:REACHX_DEPLOY_MODE
$DefaultEnv   = if ($env:REACHX_DEPLOY_ENV) { $env:REACHX_DEPLOY_ENV } else { 'dev' }

if (-not $SupabaseUrl -or -not $SupabaseKey) {
    Write-Log "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in env." "ERROR"
    exit 1
}
if (-not $RepoPath -or -not (Test-Path $RepoPath)) {
    Write-Log "REACHX_REPO_PATH is not set or path not found: '$RepoPath'" "ERROR"
    exit 1
}
if (-not $DeployMode -or ($DeployMode -notin @('cloudflare','vercel'))) {
    Write-Log "REACHX_DEPLOY_MODE must be 'cloudflare' or 'vercel'." "ERROR"
    exit 1
}

$headers = @{
    apikey         = $SupabaseKey
    Authorization  = "Bearer $SupabaseKey"
    Accept         = "application/json"
    "Content-Type" = "application/json"
}

function Get-QueuedDeployCommands {
    Write-Log "Fetching queued deploy commands for ReachX..."

    $url = "$SupabaseUrl/rest/v1/az_commands?project=eq.reachx&action=eq.deploy&status=eq.queued&order=id.asc"
    try {
        $resp = Invoke-RestMethod -Method Get -Uri $url -Headers $headers
        return @($resp)
    }
    catch {
        Write-Log ("Failed to fetch az_commands: {0}" -f $_.Exception.Message) "ERROR"
        return @()
    }
}

function Update-CommandStatus {
    param(
        [int]$CommandId,
        [string]$Status,
        [string]$ErrorMessage
    )

    $url = "$SupabaseUrl/rest/v1/az_commands?id=eq.$CommandId"

    # Keep it minimal to avoid schema mismatches
    $body = @{
        status = $Status
    }

    $json = $body | ConvertTo-Json -Depth 5

    try {
        Invoke-RestMethod -Method Patch -Uri $url -Headers $headers -Body $json
        Write-Log "Updated command #$CommandId status -> '$Status'."
    }
    catch {
        Write-Log ("Failed updating command #{0}: {1}" -f $CommandId, $_.Exception.Message) "ERROR"
    }
}

function CreateProjectRun {
    param(
        [int]$CommandId,
        [string]$Env,
        [string]$InitialStatus,
        [string]$GitCommit
    )

    # Temporary stub: we are not writing az_project_runs yet
    Write-Log "CreateProjectRun stub: command #$CommandId (env=$Env, status=$InitialStatus, commit=$GitCommit)."
    return $null
}

function UpdateProjectRun {
    param(
        [int]$RunId,
        [string]$Status,
        [string]$LogsUrl,
        [string]$ErrorMessage
    )

    if (-not $RunId) { return }

    $url = "$SupabaseUrl/rest/v1/az_project_runs?id=eq.$RunId"
    $body = @{
        status = $Status
    }

    $meta = @{}
    if ($LogsUrl) {
        $meta.logs_url = $LogsUrl
    }
    if ($ErrorMessage) {
        $meta.error_message = $ErrorMessage
    }
    if ($meta.Count -gt 0) {
        $body.meta = $meta
    }

    $json = $body | ConvertTo-Json -Depth 10

    try {
        Invoke-RestMethod -Method Patch -Uri $url -Headers $headers -Body $json
        Write-Log "Updated az_project_runs #$RunId -> status='$Status'."
    }
    catch {
        Write-Log ("Failed updating az_project_runs #{0}: {1}" -f $RunId, $_.Exception.Message) "ERROR"
    }
}

function Get-GitCommit {
    param(
        [string]$Path
    )
    try {
        Push-Location $Path
        $commit = git rev-parse HEAD 2>$null
        Pop-Location
        return $commit
    }
    catch {
        try { Pop-Location } catch {}
        Write-Log "Could not read git commit in '$Path'." "WARN"
        return $null
    }
}

function Build-ReachX {
    param(
        [string]$Path
    )
    Write-Log "Starting build for ReachX at '$Path'..."
    Push-Location $Path
    try {
        npm install
        if ($LASTEXITCODE -ne 0) {
            throw "npm install failed with exit code $LASTEXITCODE"
        }

        npm run build
        if ($LASTEXITCODE -ne 0) {
            throw "npm run build failed with exit code $LASTEXITCODE"
        }

        Write-Log "Build completed successfully."
        return $true
    }
    catch {
        Write-Log ("Build failed: {0}" -f $_.Exception.Message) "ERROR"
        return $false
    }
    finally {
        Pop-Location
    }
}

function Deploy-ReachX {
    param(
        [string]$Path,
        [string]$Env
    )

    Write-Log "Starting deploy for ReachX (mode=$DeployMode, env=$Env)..."
    Push-Location $Path
    $logsFile = Join-Path $Path ("deploy-logs-{0}-{1}.txt" -f $Env, (Get-Date -Format 'yyyyMMdd-HHmmss'))
    try {
        if ($DeployMode -eq 'cloudflare') {
            $cmd = "wrangler pages deploy dist"
            Write-Log "Running: $cmd"

            $output = & wrangler pages deploy dist 2>&1
            $output | Out-File -FilePath $logsFile -Encoding utf8

            # For Cloudflare we still trust the exit code
            if ($LASTEXITCODE -ne 0) {
                $errText = ($output -join "`n")
                throw "Cloudflare deploy failed with exit code $LASTEXITCODE. Output:`n$errText"
            }

            $joined = $output -join "`n"
            $urlMatch = [regex]::Match($joined, "https?://[^\s]+")
            $deployUrl = if ($urlMatch.Success) { $urlMatch.Value } else { $null }

            Write-Log "Cloudflare deploy complete. URL=$deployUrl"
            return @{ success = $true; logsPath = $logsFile; url = $deployUrl }
        }
        elseif ($DeployMode -eq 'vercel') {
            $cmd = "vercel deploy --prod --yes"
            Write-Log "Running: $cmd"

            # capture ALL output and write it to file
            $output = & vercel deploy --prod --yes 2>&1
            $output | Out-File -FilePath $logsFile -Encoding utf8

            $joined = $output -join "`n"

            # Look for a "Production: https://..." line
            $prodRegex = [regex]"Production:\s+(https?://\S+)"
            $match = $prodRegex.Match($joined)

            if ($match.Success) {
                $deployUrl = $match.Groups[1].Value
                Write-Log "Vercel deploy complete. URL=$deployUrl"
                return @{ success = $true; logsPath = $logsFile; url = $deployUrl }
            }
            else {
                # No Production URL => treat as failure, include full output
                throw "Vercel deploy did not output a Production URL. Raw output:`n$joined"
            }
        }
        else {
            throw "Unsupported DeployMode: $DeployMode"
        }
    }
    catch {
        $msg = $_.Exception.Message
        Write-Log ("Deploy failed: {0}" -f $msg) "ERROR"
        return @{ success = $false; logsPath = $logsFile; url = $null; error = $msg }
    }
    finally {
        Pop-Location
    }
}

Write-Log "=== Jarvis-DeploymentAgent-ReachX starting ==="
Write-Log "RepoPath=$RepoPath, DeployMode=$DeployMode"

do {
    $commands = Get-QueuedDeployCommands

    if ($commands.Count -eq 0 -or ($commands.Count -eq 1 -and -not $commands[0])) {
        Write-Log "No queued deploy commands found for ReachX."
        if ($Once -eq 'once') { break }
        Start-Sleep -Seconds 15
        continue
    }

    foreach ($cmd in $commands) {
        $commandId = [int]$cmd.id
        Write-Log "Processing deploy command #$commandId..."

        Update-CommandStatus -CommandId $commandId -Status 'in_progress' -ErrorMessage $null

        $env = $DefaultEnv
        if ($cmd.meta -and $cmd.meta.env) {
            $env = $cmd.meta.env
        }

        $gitCommit = Get-GitCommit -Path $RepoPath
        $runId = CreateProjectRun -CommandId $commandId -Env $env -InitialStatus 'building' -GitCommit $GitCommit

        $buildOk = Build-ReachX -Path $RepoPath
        if (-not $buildOk) {
            UpdateProjectRun -RunId $runId -Status 'failed' -LogsUrl $null -ErrorMessage "Build failed"
            Update-CommandStatus -CommandId $commandId -Status 'error' -ErrorMessage "Build failed"
            continue
        }

        UpdateProjectRun -RunId $runId -Status 'deploying' -LogsUrl $null -ErrorMessage $null

        $deployResult = Deploy-ReachX -Path $RepoPath -Env $env
        if (-not $deployResult.success) {
            UpdateProjectRun -RunId $runId -Status 'failed' -LogsUrl $deployResult.logsPath -ErrorMessage $deployResult.error
            Update-CommandStatus -CommandId $commandId -Status 'error' -ErrorMessage "Deploy failed"
            continue
        }

        UpdateProjectRun -RunId $runId -Status 'ok' -LogsUrl $deployResult.url -ErrorMessage $null
        Update-CommandStatus -CommandId $commandId -Status 'done' -ErrorMessage $null

        Write-Log "Finished deploy command #$commandId."
    }

    if ($Once -eq 'once') { break }
    Start-Sleep -Seconds 10
} while ($true)

Write-Log "=== Jarvis-DeploymentAgent-ReachX exiting ==="
