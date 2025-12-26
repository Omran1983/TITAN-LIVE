$dir = Join-Path $env:AZ_HOME "logs\plans"
$last = Get-ChildItem $dir -Filter *-plan-*.txt | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($null -eq $last) { Write-Host "No plans yet."; exit 0 }
Write-Host "Showing: $($last.FullName)`n---`n"
Get-Content $last.FullName
