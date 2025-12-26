cd F:\AION-ZERO\scripts

$taskName = "Jarvis-RunLoop-reachx"

# Define the action: run the loop for reachx with your model
$action = New-ScheduledTaskAction `
  -Execute "powershell.exe" `
  -Argument "-NoProfile -ExecutionPolicy Bypass -File `"`"F:\AION-ZERO\scripts\Jarvis-RunProjectLoop.ps1`"`" -Project `"reachx`" -Model `"qwen2.5-coder:7b`""

# Trigger: every 5 minutes
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue)

# Optional: run even if you are not logged in (if you want that)
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType S4U -RunLevel Highest

# Register task
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal
