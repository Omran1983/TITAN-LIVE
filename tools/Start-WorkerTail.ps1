param([string]$Log='F:\AION-ZERO\logs\wrangler-tail-educonnect-api-current.log')
try { Get-Process wrangler -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue } catch {}
cd F:\Jarvis\cf-worker
wrangler whoami *> $null
# stream to file safely; Out-File keeps the handle – single writer only
wrangler tail educonnect-api --format json | ForEach-Object {
  $_ | Out-File -FilePath $Log -Append -Encoding UTF8
}
