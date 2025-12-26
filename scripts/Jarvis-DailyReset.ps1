param(
  [string]$WatcherTask = "JARVIS-Watcher",
  [string]$HCTask = "JARVIS-Healthcheck",
  [string]$AZHome = "F:\AION-ZERO",
  [string]$WatcherPS = "F:\AION-ZERO\scripts\Jarvis-Watcher.ps1",
  [string]$HCPS = "F:\AION-ZERO\scripts\Enqueue-Healthcheck.ps1"
)
$actWatcher = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$WatcherPS`" -AZHome `"$AZHome`" -CycleSec 60" -WorkingDirectory $AZHome
$actHC      = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$HCPS`" -AZHome `"$AZHome`"" -WorkingDirectory $AZHome

$trgW1 = New-ScheduledTaskTrigger -Once -At (Get-Date).Date.AddSeconds(5) `
          -RepetitionInterval (New-TimeSpan -Minutes 3) `
          -RepetitionDuration (New-TimeSpan -Days 1)
$trgW2 = New-ScheduledTaskTrigger -AtLogOn

$trgHC = New-ScheduledTaskTrigger -Once -At (Get-Date).Date.AddSeconds(10) `
          -RepetitionInterval (New-TimeSpan -Minutes 5) `
          -RepetitionDuration (New-TimeSpan -Days 1)

$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

# Update/ensure actions + triggers (no delete/stop)
try { Set-ScheduledTask -TaskName $WatcherTask -Action $actWatcher -Trigger @($trgW1,$trgW2) -Principal $principal } catch {}
try { Set-ScheduledTask -TaskName $HCTask     -Action $actHC      -Trigger $trgHC        -Principal $principal } catch {}
