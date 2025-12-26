param(
    [Parameter(Mandatory = $true)][string]$Project
)

$ErrorActionPreference = "Stop"

Write-Host "=== Jarvis-ApplyCodePatches ($Project) starting ==="

# Resolve dirs
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path $scriptDir -Parent
Write-Host "ScriptDir: $scriptDir"
Write-Host "RepoRoot : $repoRoot"

# Load env
. "$scriptDir\Jarvis-LoadEnv.ps1"

# Supabase env
$supabaseUrl = $env:SUPABASE_URL
$serviceKey  = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $supabaseUrl -or -not $serviceKey) {
    throw "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set in environment."
}

$sbHeaders = @{
    apikey        = $serviceKey
    Authorization = "Bearer $serviceKey"
    Prefer        = "return=representation"
}

function Update-Command {
    param(
        [Parameter(Mandatory = $true)][int]$Id,
        [hashtable]$Fields
    )

    $body = @($Fields) | ConvertTo-Json -Depth 10
    $url  = "$supabaseUrl/rest/v1/az_commands?id=eq.$Id"

    Invoke-RestMethod -Method Patch `
        -Uri $url `
        -Headers $sbHeaders `
        -ContentType "application/json" `
        -Body $body | Out-Null
}

function Get-CompletedCodeCommands {
    param(
        [string]$Project
    )

    # status=completed, action=code, result_json not null
    $url = "$supabaseUrl/rest/v1/az_commands?select=*&project=eq.$Project&action=eq.code&status=eq.completed&result_json=not.is.null&order=id.asc"

    Write-Host "[PatchAgent] Fetching completed code commands from:"
    Write-Host "  $url"

    $resp = Invoke-RestMethod -Method Get `
        -Uri $url `
        -Headers $sbHeaders

    if ($resp -is [System.Array]) { return $resp }
    if ($resp) { return @($resp) }
    return @()
}

function Ensure-DirectoryForFile {
    param(
        [string]$FullPath
    )

    $dir = Split-Path $FullPath -Parent
    if (-not (Test-Path $dir)) {
        Write-Host "[PatchAgent] Creating directory: $dir"
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Apply-FileChange {
    param(
        [string]$Path,
        [string]$Mode,
        [string]$PatchText
    )

    # Path is relative from repo root
    $fullPath = Join-Path $repoRoot $Path

    if ($Mode -eq "replace") {
        Write-Host "[PatchAgent] [replace] $Path"
        Ensure-DirectoryForFile -FullPath $fullPath
        [System.IO.File]::WriteAllText($fullPath, $PatchText)
        return "replace:$Path"
    }
    elseif ($Mode -eq "patch") {
        # For now, write patch text to a .patch file next to the target
        $patchPath = $fullPath + ".patch"
        Write-Host "[PatchAgent] [patch->file] $Path -> $(Split-Path $patchPath -Leaf)"
        Ensure-DirectoryForFile -FullPath $patchPath
        [System.IO.File]::WriteAllText($patchPath, $PatchText)
        return "patchfile:$Path"
    }
    else {
        Write-Warning "[PatchAgent] Unknown mode '$Mode' for path '$Path' - skipping."
        return "unknownmode:$Path"
    }
}

# === Main ===

$commands = Get-CompletedCodeCommands -Project $Project

if ($commands.Count -eq 0) {
    Write-Host "[PatchAgent] No completed code commands with result_json for project $Project. Exiting."
    return
}

foreach ($cmd in $commands) {
    $commandId = [int]$cmd.id
    Write-Host ""
    Write-Host "=== Applying patches for command #$commandId ==="

    $resultJson = [string]$cmd.result_json
    if (-not $resultJson) {
        Write-Warning "[PatchAgent] Command #$commandId has empty result_json - skipping."
        continue
    }

    $applied  = @()
    $hadError = $false
    $errorMsg = $null

    try {
        $parsed = $resultJson | ConvertFrom-Json

        if (-not $parsed.files) {
            Write-Host "[PatchAgent] Command #$commandId has no files[] in result_json - skipping."
        }
        else {
            foreach ($file in $parsed.files) {
                $path  = [string]$file.path
                $mode  = [string]$file.mode
                $patch = [string]$file.patch

                if (-not $path) {
                    Write-Warning "[PatchAgent] Command #$commandId encountered file entry with empty path - skipping."
                    continue
                }

                $summary = Apply-FileChange -Path $path -Mode $mode -PatchText $patch
                if ($summary) {
                    $applied += $summary
                }
            }
        }
    }
    catch {
        $hadError = $true
        $errorMsg = "PatchAgent error for id=$($commandId): $($_.Exception.Message)"
        Write-Warning $errorMsg
    }

    # Update command record with patch status
    try {
        if ($hadError) {
            Update-Command -Id $commandId -Fields @{
                status        = "error"
                error_message = $errorMsg
                updated_at    = (Get-Date).ToString("o")
            }
        }
        else {
            $logText = $null
            if ($applied.Count -gt 0) {
                $logText = "PatchAgent applied: " + ($applied -join ", ")
            }

            Update-Command -Id $commandId -Fields @{
                status     = "patched"
                logs       = $logText
                updated_at = (Get-Date).ToString("o")
            }
        }
    }
    catch {
        Write-Warning "[PatchAgent] Failed to update id=$($commandId) after patching: $($_.Exception.Message)"
    }
}

Write-Host "[PatchAgent] Finished applying patches for project $Project."
