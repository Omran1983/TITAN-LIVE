$ErrorActionPreference='Stop'
$Src = 'F:\AION-ZERO\py'
$Dst = 'F:\Backups\AZ\az_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.zip'
$ex = @('\venv\','\azdash\logs\','\__pycache__\')
$list = Get-ChildItem -Recurse -File $Src | Where-Object {
  $rel = .FullName.Substring($Src.Length)
  -not ( | ForEach-Object { $rel -like ('*' +  + '*') }) -contains $true
} | Select -Expand FullName
if (-not $list) { $list = Get-ChildItem -Recurse -File $Src | Select -Expand FullName }
Compress-Archive -Path $list -DestinationPath $Dst -Force
Write-Host $Dst
