$ErrorActionPreference = 'SilentlyContinue'

$CurLog = 'F:\AION-ZERO\logs\wrangler-tail-educonnect-api-current.log'

# Kill any prior wrangler tails
Get-CimInstance Win32_Process | ? { $_.CommandLine -match 'wrangler.*\btail\b' } |
  % { try { Stop-Process -Id $_.ProcessId -Force } catch {} }

# Resolve wrangler
try { $wc = Get-Command wrangler -ErrorAction Stop } catch { throw 'wrangler not found: install or add to PATH' }
$src = $wc.Source
$ext = [IO.Path]::GetExtension($src).ToLower()

# Ensure CF token
$tok = [Environment]::GetEnvironmentVariable('CLOUDFLARE_API_TOKEN','User')
if(-not $tok){ throw 'Missing CLOUDFLARE_API_TOKEN (User). Run: wrangler whoami' }

# Ensure log exists
if(!(Test-Path $CurLog)){ '' | Out-File $CurLog -Encoding UTF8 }

# Build launch (no fragile quotes — use format strings)
switch($ext){
  '.ps1' {
    $exe  = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    $args = ('-NoProfile -ExecutionPolicy Bypass -File "{0}" tail educonnect-api --format json >> "{1}" 2>&1' -f $src, $CurLog)
  }
  '.cmd' {
    $exe  = 'cmd.exe'
    $args = ('/c ""{0}" tail educonnect-api --format json >> "{1}" 2>&1"' -f $src, $CurLog)
  }
  default {
    $exe  = $src
    $args = ('tail educonnect-api --format json >> "{0}" 2>&1' -f $CurLog)
  }
}

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName         = $exe
$psi.Arguments        = $args
$psi.WorkingDirectory = 'F:\Jarvis\cf-worker'
$psi.CreateNoWindow   = $true
$psi.UseShellExecute  = $false
$psi.Environment['CLOUDFLARE_API_TOKEN'] = $tok
[Diagnostics.Process]::Start($psi) | Out-Null
Start-Sleep 2
'started'
