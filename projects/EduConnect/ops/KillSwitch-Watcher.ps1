param(
  [string]$TaskName = "Scout-Scrape",
  [int]$WindowMinutes = 60,
  [int]$MaxFails = 3
)
$since = (Get-Date).AddMinutes(-$WindowMinutes)
$err = Get-ChildItem F:\EduConnect\logs\*.err.log -ErrorAction SilentlyContinue |
  Where-Object { $_.LastWriteTime -ge $since }
if ($err.Count -ge $MaxFails) {
  Disable-ScheduledTask -TaskName $TaskName | Out-Null
  Write-Warning "Kill-switch tripped: disabled $TaskName after $($err.Count) fails in $WindowMinutes min."
}
