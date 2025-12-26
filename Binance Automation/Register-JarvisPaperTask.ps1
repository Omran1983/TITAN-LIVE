$ErrorActionPreference = "Stop"
$Base  = Split-Path -Parent (Resolve-Path -LiteralPath .).Path
$Start = Join-Path $Base 'Start-JarvisPaper.ps1'
if (!(Test-Path $Start)) { throw "Missing: $Start" }
$Pwsh = (Get-Command pwsh.exe -ErrorAction SilentlyContinue)?.Source
if (-not $Pwsh) { $Pwsh = 'C:\Program Files\PowerShell\7\pwsh.exe' }
if (!(Test-Path $Pwsh)) { throw "pwsh.exe not found at: $Pwsh" }

$TaskName = 'JARVIS Paper (User Login)'
$action   = New-ScheduledTaskAction -Execute $Pwsh -Argument ('-NoLogo -NoProfile -File "{0}"' -f $Start) -WorkingDirectory $Base
$trigger  = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive -RunLevel Limited

try { Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue } catch {}
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal | Out-Null
Write-Host "Registered scheduled task: $TaskName"
