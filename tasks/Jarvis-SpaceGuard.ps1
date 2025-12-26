[CmdletBinding()]
param()
$ErrorActionPreference = "Continue"

# --- Config ---
$TargetFreeGB   = 205        # Stop when C: free space reaches this
$MaxMinutes     = 90         # Hard time limit
$MaxMoves       = 3          # Max folders/files to relocate this run
$ArchiveRoot    = "F:\Archive\SpaceGuard_{0:yyyyMM}" -f (Get-Date)
$UserProfile    = $env:USERPROFILE
$LogPath        = Join-Path "F:\AION-ZERO\logs" ("spaceguard_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))

# --- Helpers ---
function Log($msg){ $line = ('[{0:HH:mm:ss}] {1}' -f (Get-Date), $msg); $line | Tee-Object -FilePath $LogPath -Append }
function SizeGB($bytes){ [math]::Round(($bytes/1GB),2) }
function DirSize($path){
  if(-not (Test-Path $path)){return 0}
  $sum = (Get-ChildItem -LiteralPath $path -Recurse -Force -EA SilentlyContinue | Measure-Object Length -Sum).Sum
  if(-not $sum){ $sum = ((Get-Item -LiteralPath $path -EA SilentlyContinue).Length) }
  if(-not $sum){ $sum = 0 }
  return $sum
}
function Clear-IfExists([string]$p){
  if(Test-Path $p){
    try { Remove-Item $p -Recurse -Force -EA Stop; Log "CLEARED: $p" }
    catch { Log "SKIP (locked): $p -> $($_.Exception.Message)" }
  }
}
function Move-WithJunction([string]$Path,[string]$NewRoot){
  if(-not (Test-Path $Path)){ Log "SKIP (missing): $Path"; return }
  $name = Split-Path $Path -Leaf
  $dest = Join-Path $NewRoot $name
  New-Item -ItemType Directory -Path $dest -Force | Out-Null
  Log ("COPY → {0} -> {1}" -f $Path,$dest)
  robocopy $Path $dest /MIR /COPYALL /XJ /R:1 /W:1 | Out-Null
  Rename-Item $Path "$($Path).bak" -EA SilentlyContinue
  cmd /c mklink /J "$Path" "$dest" | Out-Null
  Remove-Item "$($Path).bak" -Recurse -Force -EA SilentlyContinue
  Log ("LINKED: {0} => {1}" -f $Path,$dest)
}
function Move-FileWithShortcut([string]$File,[string]$NewRoot){
  if(-not (Test-Path $File)){ Log "SKIP (missing): $File"; return }
  New-Item -ItemType Directory -Path $NewRoot -Force | Out-Null
  $dest = Join-Path $NewRoot (Split-Path $File -Leaf)
  Move-Item -LiteralPath $File -Destination $dest -Force
  # Create shortcut back in original folder
  $shell = New-Object -ComObject WScript.Shell
  $lnk   = Join-Path (Split-Path $File -Parent) ("{0}.lnk" -f [IO.Path]::GetFileNameWithoutExtension($File))
  $sc    = $shell.CreateShortcut($lnk); $sc.TargetPath = $dest; $sc.Save()
  Log ("MOVED FILE: {0} -> {1} (shortcut created)" -f $File,$dest)
}

# --- Start ---
$sw = [Diagnostics.Stopwatch]::StartNew()
Log "--- JARVIS SpaceGuard start ---"
$beforeC = [math]::Round((Get-PSDrive C).Free/1GB,1)
$beforeF = [math]::Round((Get-PSDrive F).Free/1GB,1)
Log ("BEFORE → C:{0}GB / F:{1}GB" -f $beforeC,$beforeF)

# Ensure archive root
New-Item -ItemType Directory -Force -Path $ArchiveRoot | Out-Null

# 1) Safe cache purges (TEMP, Chromium, VSCode, package mgrs)
$cachePaths = @(
  "$env:TEMP\*",
  "$env:LOCALAPPDATA\Temp\*",
  "C:\Windows\Temp\*",
  "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*",
  "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache\*",
  "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache\*",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache\*",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\GPUCache\*",
  "$env:APPDATA\Code\Cache\*",
  "$env:APPDATA\Code\CachedData\*",
  "$env:APPDATA\Code\Service Worker\CacheStorage\*",
  "$env:APPDATA\Code\Service Worker\ScriptCache\*",
  "$env:APPDATA\Code\User\workspaceStorage\*",
  "$env:LOCALAPPDATA\CrashDumps\*"
)
$cachePaths | ForEach-Object { Clear-IfExists $_ }
try { npm cache clean --force 2>$null | Out-Null } catch {}
try { pnpm store prune 2>$null         | Out-Null } catch {}
try { py -3 -m pip cache purge 2>$null | Out-Null } catch {}

# 2) OneDrive dehydrate (cloud-only), if present
$one = Join-Path $UserProfile 'OneDrive'
if(Test-Path $one){ try { attrib -P +U "$one\*" /S /D; Log "OneDrive dehydrated (unpinned to cloud-only)" } catch { Log "OneDrive hydrate/dehydrate skipped: $($_.Exception.Message)" } }

# 3) Heaviest user areas: Desktop, Downloads (move to F:\Archive with junction/shortcut)
$areas = @(
  @{Root= (Join-Path $UserProfile 'Desktop');    Label='Desktop'},
  @{Root= (Join-Path $UserProfile 'Downloads');  Label='Downloads'}
)
$items = @()
foreach($a in $areas){
  if(Test-Path $a.Root){
    # Top-level directories (compute sizes)
    Get-ChildItem $a.Root -Directory -Force -EA SilentlyContinue | ForEach-Object {
      $sz = DirSize $_.FullName
      $items += [pscustomobject]@{ Area=$a.Label; Type='Dir'; Path=$_.FullName; Bytes=$sz; SizeGB=(SizeGB $sz) }
    }
    # Big files directly under the root
    Get-ChildItem $a.Root -File -Force -EA SilentlyContinue | Sort-Object Length -Descending | Select-Object -First 20 | ForEach-Object {
      $items += [pscustomobject]@{ Area=$a.Label; Type='File'; Path=$_.FullName; Bytes=$_.Length; SizeGB=(SizeGB $_.Length) }
    }
  }
}
$heavy = $items | Sort-Object Bytes -Descending | Where-Object { $_.SizeGB -ge 2 } | Select-Object -First 15
if($heavy){ Log "TOP CANDIDATES:`n$($heavy | Format-Table Area,Type,SizeGB,Path -Auto | Out-String)" } else { Log "No items ≥2GB in Desktop/Downloads"; }

$moves=0
foreach($h in $heavy){
  if($moves -ge $MaxMoves){ break }
  $freeC = [math]::Round((Get-PSDrive C).Free/1GB,1)
  if($freeC -ge $TargetFreeGB){ Log ("Target met (C:{0}GB). Stopping moves." -f $freeC); break }

  if($h.Type -eq 'Dir'){
    Move-WithJunction -Path $h.Path -NewRoot $ArchiveRoot
  } else {
    Move-FileWithShortcut -File $h.Path -NewRoot $ArchiveRoot
  }
  $moves++
}

# 4) Final snapshot
$afterC = [math]::Round((Get-PSDrive C).Free/1GB,1)
$afterF = [math]::Round((Get-PSDrive F).Free/1GB,1)
$gainC  = [math]::Round(($afterC - $beforeC),1)
$gainF  = [math]::Round(($afterF - $beforeF),1)
Log ("AFTER → C:{0}GB (+{2}GB) / F:{1}GB (+{3}GB)" -f $afterC,$afterF,$gainC,$gainF)
Log ("Moved: {0} item(s); Elapsed: {1:n1} min" -f $moves, $sw.Elapsed.TotalMinutes)

# 5) Stop rule
if($afterC -lt $TargetFreeGB){ Log ("STOP RULE: C still < {0}GB. Further action deferred to manual review." -f $TargetFreeGB) }
Log "--- JARVIS SpaceGuard end ---"
