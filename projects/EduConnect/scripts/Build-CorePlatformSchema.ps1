param()
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$log = "F:\EduConnect\logs\schema_$stamp.log"
$ensure = @("F:\EduConnect\data","F:\EduConnect\logs")
$ensure | % { if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ | Out-Null } }
"OK,{0:o},stub schema build" -f (Get-Date) | Out-File -FilePath $log -Encoding UTF8
Write-Host "Schema stub complete -> $log"
exit 0
