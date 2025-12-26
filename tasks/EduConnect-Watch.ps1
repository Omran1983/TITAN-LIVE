param([string]$Root="F:\EduConnect\site",[int]$Port=8787)
$ErrorActionPreference = "SilentlyContinue"

# Already healthy?
$ok = $false
if (Get-NetTCPConnection -LocalPort $Port -State Listen) {
  try { if ((Invoke-WebRequest -UseBasicParsing ("http://localhost:{0}/" -f $Port) -TimeoutSec 5).StatusCode -eq 200) { $ok = $true } } catch {}
}
if ($ok) { return }

# Heal: start Python http.server in background
$py = Get-Command py.exe -EA SilentlyContinue
if ($py) {
  Start-Process -WindowStyle Hidden -FilePath $py.Path -ArgumentList @('-3','-m','http.server',"$Port",'--directory',$Root)
} else {
  $p2 = Get-Command python.exe -EA SilentlyContinue
  if ($p2) { Start-Process -WindowStyle Hidden -FilePath $p2.Path -ArgumentList @('-m','http.server',"$Port",'--directory',$Root) }
}
