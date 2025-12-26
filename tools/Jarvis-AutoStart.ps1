$env:AZ_HOME='F:\AION-ZERO'
$env:EDU_ONLY='1'
$env:EDU_WEB_DISABLE='1'
$env:JARVIS_EMAIL_DISABLE='1'
$env:EDU_API_HEALTH='https://educonnect-api.dubsy1983-51e.workers.dev/health'
Start-Process powershell.exe -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-STA','-File',""F:\AION-ZERO\tools\Jarvis-Monitor.ps1""
$ts=Get-Date -Format yyyyMMdd-HHmmss
$log=Join-Path "F:\AION-ZERO\logs" "wrangler-tail-educonnect-api-$ts.log"
Start-Process powershell.exe -ArgumentList '-NoProfile','-Command',"cd F:\Jarvis\cf-worker; wrangler whoami *> $null; wrangler tail educonnect-api --format pretty *>> "$log"" -WindowStyle Hidden
