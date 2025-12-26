$ErrorActionPreference = "Stop"

. "F:\AION-ZERO\scripts\Load-Supabase.ps1"

$uri = "$SBURL/rest/v1/az_commands?select=id&limit=1"

try {
    Write-Host ">>> Testing SELECT from az_commands at $SBURL..."
    $rows = Invoke-RestMethod -Uri $uri -Headers $SBHeaders -Method Get
    Write-Host "Table exists. Rows returned:" ($rows | Measure-Object).Count
}
catch {
    Write-Host "ERROR talking to az_commands:" -ForegroundColor Red
    Write-Host $_.ErrorDetails.Message
}
