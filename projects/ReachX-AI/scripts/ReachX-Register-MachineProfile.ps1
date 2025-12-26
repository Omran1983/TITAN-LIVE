# ReachX-Register-MachineProfile.ps1
# Logs this machine's Windows Experience Index into a CSV for ReachX / Jarvis.

$logRoot = "F:\ReachX-AI\logs"
$logFile = Join-Path $logRoot "machine_profile.csv"

if (!(Test-Path $logRoot)) {
    New-Item -ItemType Directory -Path $logRoot | Out-Null
}

# Get WinSAT scores (same thing you just ran)
$ws = Get-WmiObject -Class Win32_WinSAT

$record = [PSCustomObject]@{
    Timestamp     = (Get-Date).ToString("o")
    Machine       = $env:COMPUTERNAME
    CPUScore      = $ws.CPUScore
    MemoryScore   = $ws.MemoryScore
    DiskScore     = $ws.DiskScore
    GraphicsScore = $ws.GraphicsScore
    D3DScore      = $ws.D3DScore
    WinSPRLevel   = $ws.WinSPRLevel
}

if (Test-Path $logFile) {
    $record | Export-Csv -Path $logFile -Append -NoTypeInformation
} else {
    $record | Export-Csv -Path $logFile -NoTypeInformation
}

Write-Host "✅ Machine profile logged to $logFile"
