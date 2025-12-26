param()
$ErrorActionPreference = "Stop"

function New-RepeatTrigger {
  param([ValidateSet('PT30M','PT1H')] [string]$Schedule)
  $dur = New-TimeSpan -Days 30            # 30-day safe window
  switch ($Schedule) {
    'PT30M' { New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(1)) -RepetitionInterval (New-TimeSpan -Minutes 30) -RepetitionDuration $dur }
    'PT1H'  { New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(2)) -RepetitionInterval (New-TimeSpan -Hours 1)   -RepetitionDuration $dur }
  }
}

function Ensure-Task {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Script,
    [Parameter(Mandatory)][ValidateSet('PT30M','PT1H')][string]$Schedule,
    [string]$Desc = ""
  )
  if (-not (Test-Path $Script)) { throw "Missing script: $Script" }

  $action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$Script`""
  $trigger   = New-RepeatTrigger -Schedule $Schedule
  $settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

  if (Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $Name -Confirm:$false | Out-Null
  }
  $taskObj = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description $Desc
  Register-ScheduledTask -TaskName $Name -InputObject $taskObj | Out-Null
  Enable-ScheduledTask -TaskName $Name | Out-Null
  Write-Host "OK Task: $Name -> $Script (SYSTEM)"
}

Ensure-Task -Name "Quicksilver-Schema" -Script "F:\EduConnect\scripts\Build-CorePlatformSchema.ps1" -Schedule "PT1H"  -Desc "Hourly schema stub"
Ensure-Task -Name "Scout-Scrape"      -Script "F:\EduConnect\agents\Scout\Run-Scrape.ps1"        -Schedule "PT30M" -Desc "30m seed scrape"

Write-Host "Tasks registered."
