param([int]$Loops=3)
for ($i=1; $i -le $Loops; $i++) {
  Write-Host ("[run-target] heartbeat {0} @ {1}" -f $i, (Get-Date -Format s))
  Start-Sleep 2
}
Write-Host "[run-target] done."
