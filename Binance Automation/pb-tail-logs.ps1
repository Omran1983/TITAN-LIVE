param([string]$Glob = ".\logs\live_*.log", [int]$PollMs = 800)
$tracked = @{}
function Start-Tail([string]$p){ if($tracked.ContainsKey($p)){return}; $tracked[$p]= (Test-Path $p) ? (Get-Item $p).Length : 0; 
Write-Host "`n--- Tailing $(Split-Path $p -Leaf) ---`n" -ForegroundColor Cyan }
Get-ChildItem $Glob -ErrorAction SilentlyContinue | % { Start-Tail $_.FullName }
while($true){
  Get-ChildItem $Glob -ErrorAction SilentlyContinue | % { Start-Tail $_.FullName }
  foreach($k in $tracked.Keys){
    if(!(Test-Path $k)){continue}; $fi=Get-Item $k; $lenNow=$fi.Length; $pos=[long]$tracked[$k]
    if($lenNow -gt $pos){ $fs=[IO.File]::Open($k,'Open','Read','ReadWrite'); try{$fs.Seek($pos,'Begin')|Out-Null;$sr=[IO.StreamReader]$fs;$txt=$sr.ReadToEnd();$sr.Close(); if($txt){$txt -split "`r?`n" | ? {$_ -ne ""} | % {$_}}; $tracked[$k]=$lenNow} finally{$fs.Close()} }
  }
  Start-Sleep -Milliseconds $PollMs
}
