# Jarvis-NodeFileOpsWorker.ps1
# Multi-node-aware FileOps Worker

. "$PSScriptRoot\Jarvis-LoadEnv.ps1"
. "$PSScriptRoot\shared\Jarvis-NodeId.ps1"
. "$PSScriptRoot\shared\Jarvis-Logger.ps1" -Component "fileops-node"
. "$PSScriptRoot\shared\Jarvis-Http.ps1"

# Load .env for SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, etc.
Set-Location (Split-Path -Parent $PSScriptRoot)
& "$PSScriptRoot\Jarvis-LoadEnv.ps1"

$nodeCode = Get-JarvisNodeCode
Write-JLog -Level INFO -Message "=== Jarvis FileOps Worker starting on node='$nodeCode' ==="

$pollSeconds = 15

function Update-CommandStatus {
    param(
        [int]$Id,
        [string]$Status,
        [string]$ErrorMessage,
        [object]$Result
    )

    $body = @{
        status        = $Status
        error_message = $ErrorMessage
    }

    if ($Result) {
        $body["result"] = ($Result | ConvertTo-Json -Depth 20)
    }

    $path = "/rest/v1/az_commands?id=eq.$Id"
    Invoke-JarvisSupabase -Method PATCH -Path $path -Body $body | Out-Null
}

function Invoke-FileOp {
    param(
        [hashtable]$Payload
    )

    $kind = $Payload.kind
    switch ($kind) {

        "write_file" {
            $path     = $Payload.path
            $content  = $Payload.content
            $encoding = $Payload.encoding

            if (-not $path)     { throw "write_file missing 'path'" }
            if (-not $content)  { $content = "" }

            $dir = Split-Path -Parent $path
            if ($dir -and -not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }

            if ($encoding -eq "utf8" -or -not $encoding) {
                [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
            }
            else {
                Set-Content -Path $path -Value $content
            }

            return @{ ok = $true; op = "write_file"; path = $path }
        }

        "append_file" {
            $path     = $Payload.path
            $content  = $Payload.content
            if (-not $path)    { throw "append_file missing 'path'" }
            if (-not $content) { $content = "" }

            $line = $content + [Environment]::NewLine
            Add-Content -Path $path -Value $line
            return @{ ok = $true; op = "append_file"; path = $path }
        }

        default {
            throw "Unsupported fileops kind: $kind"
        }
    }
}

while ($true) {
    try {
        # 1) Get next queued command for THIS node
        $path = "/rest/v1/az_commands?status=eq.queued&agent=eq.fileops&node_code=eq.$nodeCode&order=created_at.asc&limit=1"
        $cmds = Invoke-JarvisSupabase -Method GET -Path $path

        if (-not $cmds -or $cmds.Count -eq 0) {
            Start-Sleep -Seconds $pollSeconds
            continue
        }

        $cmd = $cmds[0]
        $id  = $cmd.id
        $rawPayload = $cmd.payload

        Write-JLog -Level INFO -Message "Processing command id=$id on node=$nodeCode"

        # Mark as in-progress
        Update-CommandStatus -Id $id -Status "running" -ErrorMessage "" -Result $null

        # Parse payload
        $payloadObj = $null
        if ($rawPayload -is [string]) {
            $payloadObj = $rawPayload | ConvertFrom-Json -Depth 20
        } else {
            $payloadObj = $rawPayload
        }

        $result = Invoke-FileOp -Payload $payloadObj

        Update-CommandStatus -Id $id -Status "completed" -ErrorMessage "" -Result $result
        Write-JLog -Level INFO -Message "Completed command id=$id"
    }
    catch {
        $err = $_.Exception.Message
        Write-JLog -Level ERROR -Message "Worker error: $err"

        if ($cmd -and $id) {
            Update-CommandStatus -Id $id -Status "failed" -ErrorMessage $err -Result $null
        }

        Start-Sleep -Seconds ($pollSeconds * 2)
    }
}
