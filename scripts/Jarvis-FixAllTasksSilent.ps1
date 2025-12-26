# F:\AION-ZERO\scripts\Jarvis-FixAllTasksSilent.ps1
# Bulk convert all PowerShell-based scheduled tasks to run silently via silent-run.vbs

$ErrorActionPreference = "Stop"

Write-Host "=== JARVIS: Bulk Task Scheduler Silencer ==="

# Where to backup old tasks
$backupDir = "F:\AION-ZERO\backups\task_scheduler_originals"
if (!(Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

# Silent wrapper path
$wrapper = "F:\AION-ZERO\scripts\silent-run.vbs"
if (!(Test-Path $wrapper)) {
    Write-Host "ERROR: Wrapper not found at $wrapper"
    exit 1
}

Write-Host "Using wrapper: $wrapper"

# Get all tasks
try {
    $allTasks = Get-ScheduledTask
} catch {
    Write-Host "ERROR: Unable to read scheduled tasks. Run PowerShell as Administrator."
    throw
}

$updatedCount = 0

foreach ($task in $allTasks) {

    # Skip Microsoft / OneDrive tasks
    if ($task.TaskPath -like "\Microsoft\*" -or $task.TaskPath -like "\OneDrive\*") {
        continue
    }

    $actions = @()
    $needsUpdate = $false

    foreach ($action in $task.Actions) {

        # Only touch powershell.exe actions
        if ($action.Execute -match "powershell.exe") {

            $args = $action.Arguments
            $psFile = $null

            # Try to extract the script path after -File
            if ($args -match '-File\s+"([^"]+)"') {
                $psFile = $Matches[1]
            } elseif ($args -match '-File\s+(\S+)') {
                $psFile = $Matches[1]
            }

            if (-not $psFile) {
                # If we can't find -File, keep original action
                $actions += $action
                continue
            }

            $fullName = "$($task.TaskPath)$($task.TaskName)"
            Write-Host "Processing task: $fullName"
            Write-Host "  Original PS script: $psFile"

            # Backup original definition
            $safeName   = $fullName.Replace("\", "_").Replace("/", "_")
            $backupFile = Join-Path $backupDir "$safeName.xml"
            try {
                Export-ScheduledTask -TaskPath $task.TaskPath -TaskName $task.TaskName |
                    Out-File -FilePath $backupFile -Encoding utf8
            } catch {
                Write-Host "  WARNING: Could not backup task XML: $($_.Exception.Message)"
            }

            # Build new silent action using VBS wrapper
            $newArgs   = "`"$wrapper`" `"$psFile`""
            $newAction = New-ScheduledTaskAction -Execute "wscript.exe" -Argument $newArgs

            $actions     += $newAction
            $needsUpdate = $true
            $updatedCount++
        }
        else {
            # Non PowerShell actions are preserved
            $actions += $action
        }
    }

    if ($needsUpdate) {
        try {
            Set-ScheduledTask -TaskPath $task.TaskPath -TaskName $task.TaskName -Action $actions | Out-Null
            Write-Host "  Updated to silent mode."
        } catch {
            Write-Host "  ERROR updating task: $($_.Exception.Message)"
        }
    }
}

Write-Host "=== DONE: Updated $updatedCount task(s) to silent execution. ==="
