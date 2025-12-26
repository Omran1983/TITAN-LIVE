$dir='F:\AION-ZERO\py\azdash\logs'
$maxDays=7
Get-ChildItem $dir -File -EA SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$maxDays) } | Remove-Item -Force -EA SilentlyContinue
