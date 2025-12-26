# F:\AION-ZERO\scripts\AZ-CommandPoller-Wrapper.ps1

$ErrorActionPreference = "Stop"

$logFile = "F:\AION-ZERO\logs\AZ-CommandPoller-wrapper.log"

function Write-WrapperLog {
    param([string]$Message)

    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$stamp] $Message" | Add-Content $logFile
}

Write-WrapperLog "Wrapper START (User=$env:USERNAME; PWD=$PWD)"

try {
    & "F:\AION-ZERO\scripts\AZ-CommandPoller.ps1"
    Write-WrapperLog "Wrapper DONE OK"
}
catch {
    Write-WrapperLog "Wrapper ERROR: $($_.Exception.Message)"
    throw
}
