# TITAN Bridge Runner Watchdog (v3.1)
# Starts runner.py if not running.

$RunnerPath = "F:\AION-ZERO\titan-bridge\runner\runner.py"
$PythonExe = "C:\Python313\python.exe"

$exists = Get-CimInstance Win32_Process | Where-Object {
    $_.CommandLine -like "*runner.py*"
}

if (-not $exists) {
    Start-Process -FilePath $PythonExe -ArgumentList $RunnerPath -WindowStyle Hidden
}
