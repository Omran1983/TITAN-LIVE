$ErrorActionPreference = 'Stop'

Write-Host "=== Jarvis-InstallAgentTestsWorker ==="

$taskName   = "Jarvis-AgentTestsWorker"
$scriptPath = "F:\AION-ZERO\scripts\Jarvis-AgentTestsWorker.ps1"

if (-not (Test-Path $scriptPath)) {
    throw "Jarvis-AgentTestsWorker.ps1 not found at $scriptPath"
}

try {
    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "Removing existing task '$taskName' ..."
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
}
catch {
    Write-Warning "Failed to remove existing task (if any): $($_.Exception.Message)"
}

Write-Host "Creating scheduled task '$taskName' ..."

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

# ✅ Use RepetitionInterval/Duration directly in the cmdlet
$trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date).AddMinutes(1) `
    -RepetitionInterval (New-TimeSpan -Minutes 5) `
    -RepetitionDuration (New-TimeSpan -Days 365)

$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings | Out-Null

Write-Host "Task '$taskName' installed. It will run every 5 minutes for 365 days."
