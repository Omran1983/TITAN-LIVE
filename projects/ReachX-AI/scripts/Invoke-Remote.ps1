param(
    [Parameter(Mandatory=$true)]
    [string]$CommandText,
    [string]$Environment = "dev",
    [int]$MinCpuScore = 8,
    [int]$MinMemoryScore = 8
)

.\ReachX-SubmitRemoteJob.ps1 `
    -Environment $Environment `
    -MinCpuScore $MinCpuScore `
    -MinMemoryScore $MinMemoryScore `
    -CommandText $CommandText
