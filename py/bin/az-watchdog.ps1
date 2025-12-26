$ErrorActionPreference='SilentlyContinue'
$API="http://127.0.0.1:8787/api/health"
$ok=False
try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 $API | Out-Null; $ok=True } catch {}
if (-not $ok) {
  Get-Process uvicorn -EA SilentlyContinue | Stop-Process -Force
  Start-Process -NoNewWindow -FilePath 'F:\AION-ZERO\py\venv\Scripts\python.exe' 
    -ArgumentList @('-m','uvicorn','azdash.api:app','--host','127.0.0.1','--port','8787') 
    -RedirectStandardOutput (Join-Path 'F:\AION-ZERO\py\azdash\logs' ("uvicorn_out_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))) 
    -RedirectStandardError  (Join-Path 'F:\AION-ZERO\py\azdash\logs' ("uvicorn_err_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss')))
}
