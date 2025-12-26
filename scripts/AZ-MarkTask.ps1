# F:\AION-ZERO\scripts\AZ-MarkTask.ps1
param(
    [Parameter(Mandatory=$true)]
    [int]$TaskId,

    [ValidateSet("pending","doing","done","blocked","cancelled")]
    [string]$Status = "done"
)

$ErrorActionPreference = "Stop"

. "F:\AION-ZERO\scripts\Load-Supabase.ps1"

$updateUri = "$SBURL/rest/v1/az_tasks?id=eq.$TaskId"

$headers = $SBHeaders.Clone()
$headers["Content-Type"] = "application/json"
$headers["Prefer"]       = "return=minimal"

$body = @{
    status      = $Status
    last_run_at = (Get-Date).ToString("o")
} | ConvertTo-Json

Invoke-RestMethod -Uri $updateUri -Headers $headers -Method Patch -Body $body | Out-Null

Write-Host "Task $TaskId marked as $Status" -ForegroundColor Green
