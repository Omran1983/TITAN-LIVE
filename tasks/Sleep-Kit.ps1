param([string]\F:\AION-ZERO\a-one-marcom = 'F:\AION-ZERO\a-one-marcom')
\F:\AION-ZERO\tasks = 'F:\AION-ZERO\tasks'
\F:\AION-ZERO\logs   = 'F:\AION-ZERO\logs'
\F:\AION-ZERO\tasks\Run-Harvis.ps1     = Join-Path \F:\AION-ZERO\tasks 'Run-Harvis.ps1'
\F:\AION-ZERO\logs\harvis_status.txt   = Join-Path \F:\AION-ZERO\logs  'harvis_status.txt'
if (!(Test-Path \F:\AION-ZERO\tasks\Run-Harvis.ps1)) { throw "Missing \F:\AION-ZERO\tasks\Run-Harvis.ps1" }
if (!(Test-Path \F:\AION-ZERO\logs)) { New-Item -ItemType Directory -Force -Path \F:\AION-ZERO\logs | Out-Null }
\C:\Program Files\PowerShell\7\pwsh.exe = (Get-Command pwsh -ErrorAction SilentlyContinue).Source; if (-not \C:\Program Files\PowerShell\7\pwsh.exe) { \C:\Program Files\PowerShell\7\pwsh.exe = (Get-Command powershell -ErrorAction Stop).Source }

# Task 1: Harvis-Loop
\ = "-NoProfile -ExecutionPolicy Bypass -File "\F:\AION-ZERO\tasks\Run-Harvis.ps1" -ProjectPath "\F:\AION-ZERO\a-one-marcom" -Hold:$false"
\ = New-ScheduledTaskAction -Execute \C:\Program Files\PowerShell\7\pwsh.exe -Argument \
\MSFT_TaskBootTrigger = New-ScheduledTaskTrigger -AtStartup
\MSFT_TaskLogonTrigger   = New-ScheduledTaskTrigger -AtLogOn
\MSFT_TaskSettings3 = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 5)
\MSFT_TaskPrincipal2  = New-ScheduledTaskPrincipal -UserId "\OMRANPERSONAL\Omran Ahmad" -RunLevel Highest
try { Unregister-ScheduledTask -TaskName 'Harvis-Loop' -Confirm:\False -ErrorAction SilentlyContinue } catch {}
Register-ScheduledTask -TaskName 'Harvis-Loop' -Action \ -Trigger @(\MSFT_TaskBootTrigger,\MSFT_TaskLogonTrigger) -Settings \MSFT_TaskSettings3 -Principal \MSFT_TaskPrincipal2 | Out-Null

# Task 2: Harvis-Guard (every 10 min for 365 days)
\F:\AION-ZERO\tasks\Harvis-Guard-Check.ps1 = Join-Path \F:\AION-ZERO\tasks 'Harvis-Guard-Check.ps1'
@'
param([string]\, [string]\, [string]\, [string]\)
try {
  if (-not (Test-Path \)) { & \ -NoProfile -ExecutionPolicy Bypass -File \ -ProjectPath \ -Hold:\False; exit 0 }
  \ = (Get-Content \ -Raw).Trim().ToLowerInvariant()
  if (\ -ne 'ok') { & \ -NoProfile -ExecutionPolicy Bypass -File \ -ProjectPath \ -Hold:\False }
} catch { }
'@ | Set-Content -Path \F:\AION-ZERO\tasks\Harvis-Guard-Check.ps1 -Encoding ASCII

\ = "-NoProfile -ExecutionPolicy Bypass -File "\F:\AION-ZERO\tasks\Harvis-Guard-Check.ps1" -StatusFile "\F:\AION-ZERO\logs\harvis_status.txt" -Runner "\C:\Program Files\PowerShell\7\pwsh.exe" -Wrapper "\F:\AION-ZERO\tasks\Run-Harvis.ps1" -Project "\F:\AION-ZERO\a-one-marcom""
\ = New-ScheduledTaskAction -Execute \C:\Program Files\PowerShell\7\pwsh.exe -Argument \
\ = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(1)) -RepetitionInterval (New-TimeSpan -Minutes 10) -RepetitionDuration (New-TimeSpan -Days 365)
try { Unregister-ScheduledTask -TaskName 'Harvis-Guard' -Confirm:\False -ErrorAction SilentlyContinue } catch {}
Register-ScheduledTask -TaskName 'Harvis-Guard' -Action \ -Trigger \ -Settings \MSFT_TaskSettings3 -Principal \MSFT_TaskPrincipal2 | Out-Null

# reset kill-switch and kick once minimized
Remove-Item (Join-Path \F:\AION-ZERO\logs 'harvis_killswitch.json') -ErrorAction SilentlyContinue
'ok' | Set-Content -Path \F:\AION-ZERO\logs\harvis_status.txt -Encoding ASCII
Start-Process -FilePath \C:\Program Files\PowerShell\7\pwsh.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', \F:\AION-ZERO\tasks\Run-Harvis.ps1, '-ProjectPath', \F:\AION-ZERO\a-one-marcom, '-Hold:$false') -WindowStyle Minimized
Start-Sleep -Seconds 3
if (Test-Path \F:\AION-ZERO\logs\harvis_status.txt) { "STATUS: " | Write-Host }
"---- TAIL ----" | Write-Host
\F:\AION-ZERO\logs\harvis_20251101_014838.log = Get-ChildItem "\F:\AION-ZERO\logs\harvis_*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Desc | Select-Object -First 1
if (\F:\AION-ZERO\logs\harvis_20251101_014838.log) { Get-Content \F:\AION-ZERO\logs\harvis_20251101_014838.log.FullName -Tail 60 }
"Done."
