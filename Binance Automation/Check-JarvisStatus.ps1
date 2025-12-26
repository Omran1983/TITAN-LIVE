$base = (Resolve-Path -LiteralPath .).Path
$csv  = "$base\journal\paper_trades_{0}.csv" -f (Get-Date -Format 'yyyy-MM-dd')

Write-Host "=== Process ==="
Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match 'Jarvis-Loop\.ps1' } |
  Select-Object ProcessId, @{n='Started';e={[datetime]::ParseExact($_.CreationDate.Split('.')[0],'yyyyMMddHHmmss',[System.Globalization.CultureInfo]::InvariantCulture)}} |
  Format-Table -AutoSize

Write-Host "`n=== Latest Logs ==="
$lo = Get-ChildItem "$base\journal\loop_*.out.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Desc | Select-Object -First 1
$le = Get-ChildItem "$base\journal\loop_*.err.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Desc | Select-Object -First 1
if ($lo) { Write-Host "`n-- OUT --"; Get-Content $lo.FullName -Tail 12 }
if ($le) { Write-Host "`n-- ERR --"; Get-Content $le.FullName -Tail 6 }

Write-Host "`n=== Ledger ==="
if (Test-Path $csv) {
  $rows = @(Import-Csv $csv)
  $rows | Group-Object side | Select-Object Name,Count | Format-Table -AutoSize
  & pwsh -NoLogo -NoProfile -File (Join-Path $base 'Get-JarvisKPIs.ps1')
} else {
  Write-Host "No CSV yet: $csv"
}
