param(
  [string]$LogPath
)
$AZ = $env:AZ_HOME
if (-not $AZ) { $AZ = (Get-Location).Path }
$logDir = Join-Path $AZ 'logs'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
if (-not $LogPath) {
  $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
  $LogPath = Join-Path $logDir "health-$ts.log"
}
$info = [ordered]@{
  time = (Get-Date).ToString("s")
  user = $env:USERNAME
  computer = $env:COMPUTERNAME
  os = (Get-CimInstance Win32_OperatingSystem).Caption
  cpu = (Get-CimInstance Win32_Processor).Name
  ram_gb = [math]::Round(((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB),2)
  vram_hint = "Use 'nvidia-smi' if NVIDIA GPU"
  top_processes = (Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Name,CPU)
}
$info | Out-File -FilePath $LogPath -Encoding UTF8
Write-Host "Health log -> $LogPath"
