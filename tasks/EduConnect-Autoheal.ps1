[CmdletBinding()] param()
$ErrorActionPreference = "Continue"
$log = Join-Path "F:\AION-ZERO\logs" ("edu_autoheal_{0:yyyyMMdd}.log" -f (Get-Date))
function Log($m){ ('[{0:HH:mm:ss}] {1}' -f (Get-Date), $m) | Tee-Object -FilePath $log -Append }
$root = "F:\EduConnect\site"
$port = 8787

# Liveness
$listen = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
$ok = $false
if ($listen) {
  try {
    $r = Invoke-WebRequest -UseBasicParsing ("http://localhost:{0}/" -f $port) -TimeoutSec 6
    if ($r.StatusCode -eq 200) { $ok = $true }
  } catch {}
}

if ($ok) { Log "OK: listener + HTTP 200"; return }

# Recover
Log "HEAL: restarting server on :$port"
# Free port
(Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue) | ForEach-Object {
  try { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue } catch {}
}

# Start: Python preferred, else HttpListener
$started = $false
$py = Get-Command py.exe -ErrorAction SilentlyContinue
if ($py) {
  Start-Process -NoNewWindow $py.Path -ArgumentList @('-3','-m','http.server',"$port",'--directory',$root)
  $started = $true
} elseif ($p2 = Get-Command python.exe -ErrorAction SilentlyContinue) {
  Start-Process -NoNewWindow $p2.Path -ArgumentList @('-m','http.server',"$port",'--directory',$root)
  $started = $true
} else {
  try { netsh http delete urlacl url=("http://localhost:{0}/" -f $port) *> $null } catch {}
  try { netsh http add urlacl url=("http://localhost:{0}/" -f $port) user="$env:USERNAME" *> $null } catch {}
  $srv = @"
param(\$root,\$port)
Add-Type -AssemblyName System.Net.HttpListener
\$l = New-Object System.Net.HttpListener
\$l.Prefixes.Add(("http://localhost:{0}/" -f \$port)); \$l.Start()
while (\$l.IsListening) {
  \$ctx = \$l.GetContext()
  try {
    \$rel = \$ctx.Request.Url.AbsolutePath.TrimStart('/'); if([string]::IsNullOrWhiteSpace(\$rel)){\$rel='index.html'}
    \$path = [IO.Path]::GetFullPath((Join-Path \$root \$rel))
    if(-not \$path.StartsWith([IO.Path]::GetFullPath(\$root))){\$ctx.Response.StatusCode=403;\$ctx.Response.Close();continue}
    if((Test-Path \$path) -and (Get-Item \$path).PSIsContainer){\$path = Join-Path \$path 'index.html'}
    if(-not (Test-Path \$path)){\$ctx.Response.StatusCode=404;\$ctx.Response.Close();continue}
    \$bytes = [IO.File]::ReadAllBytes(\$path)
    \$ctx.Response.ContentLength64 = \$bytes.Length
    \$ctx.Response.OutputStream.Write(\$bytes,0,\$bytes.Length)
    \$ctx.Response.OutputStream.Close()
  } catch { try{\$ctx.Response.StatusCode=500;\$ctx.Response.Close()}catch{} }
}
"@
  $tmp = Join-Path $env:TEMP 'ec_server.ps1'
  $srv | Set-Content -Path $tmp -Encoding UTF8
  Start-Process -WindowStyle Hidden PowerShell -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$tmp`"","-root","`"$root`"","-port',"$port")
  $started = $true
}

Start-Sleep -Seconds 2
try {
  $code = (Invoke-WebRequest -UseBasicParsing ("http://localhost:{0}/" -f $port) -TimeoutSec 6).StatusCode
  if ($code -eq 200) { Log "HEAL OK: HTTP 200 on :$port" } else { Log ("HEAL WARN: HTTP {0}" -f $code) }
} catch { Log ("HEAL FAIL: " + $_.Exception.Message) }
