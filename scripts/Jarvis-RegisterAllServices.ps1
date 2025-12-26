$ErrorActionPreference = "Stop"

Write-Host "=== (Re)registering Jarvis background services (user-level) ==="

$scriptPath = "F:\AION-ZERO\scripts"

$services = @(
    @{ Name = "Jarvis_CommandAgent"; Script = "$scriptPath\Jarvis-CommandAgent.ps1" },
    @{ Name = "Jarvis_NotifyWorker"; Script = "$scriptPath\Jarvis-NotifyWorker.ps1" },
    @{ Name = "Jarvis_CommandsApi";  Script = "$scriptPath\Jarvis-CommandsApi.ps1" }
)

foreach ($svc in $services) {
    $taskName   = $svc.Name
    $scriptFile = $svc.Script

    Write-Host "Registering: $taskName ..."

    if (-not (Test-Path $scriptFile)) {
        Write-Host "  WARNING: Script not found: $scriptFile - skipping"
        continue
    }

    $action = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptFile`""

    # Run when current user logs on
    $trigger = New-ScheduledTaskTrigger -AtLogOn

    try {
        $task = New-ScheduledTask -Action $action -Trigger $trigger
        Register-ScheduledTask -TaskName $taskName -InputObject $task -Force
        Write-Host ("  OK: Registered {0}" -f $taskName)
    }
    catch {
        Write-Host ("  ERROR: Failed for {0}" -f $taskName)
        Write-Host ("         {0}" -f $_.Exception.Message)
    }
}

Write-Host "=== Done. All Jarvis services (user-level) installed. ==="
