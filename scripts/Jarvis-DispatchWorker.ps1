# Jarvis-DispatchWorker.ps1
# Runs centrally; ensures commands have node assignment and are dispatched.

. "$PSScriptRoot\shared\Jarvis-NodeId.ps1"
. "$PSScriptRoot\shared\Jarvis-Logger.ps1" -Component "dispatch"
. "$PSScriptRoot\shared\Jarvis-Http.ps1"

$nodeCode = Get-JarvisNodeCode -Override "NODE-HQ"
Write-JLog -Level INFO -Message "=== Jarvis Dispatch Worker starting on node='$nodeCode' ==="

$pollSeconds = 10

while ($true) {
    try {
        # 1) Fetch commands that are queued and not yet assigned to a node
        $path = "/rest/v1/az_commands?status=eq.queued&node_code=is.null&order=created_at.asc&limit=20"
        $cmds = Invoke-JarvisSupabase -Method GET -Path $path

        if (-not $cmds -or $cmds.Count -eq 0) {
            Start-Sleep -Seconds $pollSeconds
            continue
        }

        foreach ($c in $cmds) {
            $id = $c.id
            $agent = $c.agent
            $payload = $c.payload

            # Simple routing rule v1:
            # - 'fileops' to NODE-HQ by default
            # - later: map agents to nodes by config/nodes.json
            $targetNode = switch ($agent) {
                "fileops"   { "NODE-HQ" }
                "sandbox"   { "NODE-PX1" }
                default     { "NODE-HQ" }
            }

            Write-JLog -Level INFO -Message "Assigning command id=$id, agent=$agent to node_code=$targetNode"

            $updateBody = @{
                node_code = $targetNode
            }

            $pathUpdate = "/rest/v1/az_commands?id=eq.$id"
            Invoke-JarvisSupabase -Method PATCH -Path $pathUpdate -Body $updateBody
        }
    }
    catch {
        Write-JLog -Level ERROR -Message "Dispatch loop error: $($_.Exception.Message)"
        Start-Sleep -Seconds ($pollSeconds * 2)
    }
}
