<# 
  JARVIS Monitor (real-time) — PS5.1 SAFE
  - No use of ?? or non-ASCII punctuation.
  - Does not read queue JSON unless the file exists.
  - Shows Watcher status, queue head, and log tail.
  Run:
    powershell -NoProfile -ExecutionPolicy Bypass -File "F:\AION-ZERO\tools\Jarvis-Monitor.ps1" -AZHome "F:\AION-ZERO"
#>

param(
  [string]$AZHome    = "F:\AION-ZERO",
  [int]   $TailLines = 300,
  [int]   $RefreshMs = 2000
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Paths
$Queue   = Join-Path $AZHome "bridge\file-queue"
$LogPath = Join-Path $AZHome ("logs\jarvis-{0}.log" -f (Get-Date -Format yyyyMMdd))

# Utils
function Add-LVRow($lv, [object[]]$cols) {
  $first = [string]$cols[0]
  $item  = New-Object System.Windows.Forms.ListViewItem($first)
  for ($i=1; $i -lt $cols.Count; $i++) {
    [void]$item.SubItems.Add([string]$cols[$i])
  }
  [void]$lv.Items.Add($item)
}

function Get-WatcherStatus {
  $out = schtasks /Query /TN "JARVIS-Watcher" /V /FO LIST 2>$null
  $h = [ordered]@{ Status=''; NextRun=''; LastRun=''; LastResult=''; StartIn=''; TaskToRun='' }
  foreach ($line in $out) {
    if     ($line -match '^\s*Status:\s+(.*)')        { $h.Status     = $Matches[1].Trim() }
    elseif ($line -match '^\s*Next Run Time:\s+(.*)') { $h.NextRun    = $Matches[1].Trim() }
    elseif ($line -match '^\s*Last Run Time:\s+(.*)') { $h.LastRun    = $Matches[1].Trim() }
    elseif ($line -match '^\s*Last Result:\s+(.*)')   { $h.LastResult = $Matches[1].Trim() }
    elseif ($line -match '^\s*Task To Run:\s+(.*)')   { $h.TaskToRun  = $Matches[1].Trim() }
    elseif ($line -match '^\s*Start In:\s+(.*)')      { $h.StartIn    = $Matches[1].Trim() }
  }
  [pscustomobject]$h
}

# Only read JSON if the file actually exists
function Parse-QueueName([string]$file) {
  $name   = [IO.Path]::GetFileName($file)
  $base   = [IO.Path]::GetFileNameWithoutExtension($file)
  $tokens = $base -split '-'
  $type   = if ($tokens.Count -ge 2) { $tokens[1] } else { '' }
  $proj   = $null
  $bot    = $type
  $w      = $null
  $ws     = ''

  if (Test-Path -LiteralPath $file) {
    try {
      $json = Get-Content -LiteralPath $file -Raw -Encoding UTF8 | ConvertFrom-Json -ea Stop
      if ($json.project) { $proj = [string]$json.project }
      elseif ($json.payload -and $json.payload.project) { $proj = [string]$json.payload.project }
      if ($json.bot) { $bot = [string]$json.bot }
    } catch {}
    try {
      $itm = Get-Item -LiteralPath $file -ea Stop
      $w   = $itm.LastWriteTime
      $ws  = $itm.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
    } catch {}
  }

  if (-not $proj -and $tokens.Count -ge 3 -and $tokens[2] -match '^[A-Z]{2,8}$') { $proj = $tokens[2] }
  if (-not $proj) { $proj = '-' }

  [pscustomobject]@{
    Name    = $name
    Project = $proj
    Bot     = $bot
    When    = $w
    WhenStr = $ws
    Full    = $file
  }
}

function Get-QueueItems([string]$Path, [int]$Top=200) {
  if (-not (Test-Path $Path)) { return @() }
  Get-ChildItem $Path -File |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First $Top |
    ForEach-Object { Parse-QueueName $_.FullName }
}

function Get-LogTail([string]$Path, [int]$Lines=300) {
  if (-not (Test-Path $Path)) { return @() }
  Get-Content $Path -Tail $Lines
}

function Parse-Activity($lines) {
  $currRun = $null
  foreach ($ln in $lines) {
    if ($ln -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}') { continue }
    $when = $ln.Substring(0,19) -replace 'T',' '
    if ($ln -match '\|\s+WATCHER\s+\|\s+start\s+\|\s+queue=.*\|\s+run=(?<run>[0-9a-f]+)') {
      $currRun = $Matches.run
      [pscustomobject]@{When=$when;Action='start';Item='';Run=$currRun;Project='';Bot='';Info='' }
      continue
    }
    if ($ln -match '\|\s+PICK\s+\|\s+(?<file>.+)$') {
      $file = $Matches.file.Trim()
      if ($file -notmatch '\.json$') { $file += '.json' }
      $full = if ([IO.Path]::IsPathRooted($file)) { $file } else { Join-Path $Queue $file }
      $parsed = Parse-QueueName $full
      [pscustomobject]@{When=$when;Action='pick';Item=$parsed.Name;Run=$currRun;Project=$parsed.Project;Bot=$parsed.Bot;Info='' }
      continue
    }
    if ($ln -match '\|\s+DONE\s+\|\s+(?<item>.+?)\s+->\s+(?<to>\w+)') {
      $item = $Matches.item.Trim()
      if ($item -notmatch '\.json$') { $item += '.json' }
      $full = if ([IO.Path]::IsPathRooted($item)) { $item } else { Join-Path $Queue $item }
      $parsed = Parse-QueueName $full
      [pscustomobject]@{When=$when;Action='done';Item=$parsed.Name;Run=$currRun;Project=$parsed.Project;Bot=$parsed.Bot;Info=("-> " + $Matches.to) }
      continue
    }
    if ($ln -match '\|\s+WATCHER\s+\|\s+idle') {
      [pscustomobject]@{When=$when;Action='idle';Item='';Run=$currRun;Project='';Bot='';Info='' }
      continue
    }
    if ($ln -match '\|\s+WATCHER\s+\|\s+end\s+\|\s+moved=(?<m>\d+)\s+\|\s+durMs=(?<d>\d+)') {
      $info = "moved=$($Matches.m) durMs=$($Matches.d)"
      [pscustomobject]@{When=$when;Action='end';Item='';Run=$currRun;Project='';Bot='';Info=$info }
      $currRun = $null
      continue
    }
  }
}

# UI
$form = New-Object System.Windows.Forms.Form
$form.Text = "JARVIS Monitor - $AZHome"
$form.Size = New-Object System.Drawing.Size(1060, 640)
$form.StartPosition = 'CenterScreen'

$lblTop = New-Object System.Windows.Forms.Label
$lblTop.Location = '10,10'; $lblTop.AutoSize = $true
$form.Controls.Add($lblTop)

$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text='Refresh'; $btnRefresh.Location='920,8'; $btnRefresh.Size='110,28'
$form.Controls.Add($btnRefresh)

$btnHC = New-Object System.Windows.Forms.Button
$btnHC.Text='Enqueue Healthcheck (AZ)'; $btnHC.Location='700,8'; $btnHC.Size='210,28'
$form.Controls.Add($btnHC)

$btnOpenLog = New-Object System.Windows.Forms.Button
$btnOpenLog.Text='Open Log'; $btnOpenLog.Location='920,40'; $btnOpenLog.Size='110,28'
$form.Controls.Add($btnOpenLog)

$btnOpenQueue = New-Object System.Windows.Forms.Button
$btnOpenQueue.Text='Open Queue'; $btnOpenQueue.Location='700,40'; $btnOpenQueue.Size='210,28'
$form.Controls.Add($btnOpenQueue)

$lblMeta = New-Object System.Windows.Forms.Label
$lblMeta.Location='10,44'; $lblMeta.AutoSize=$true
$form.Controls.Add($lblMeta)

$lblFilter = New-Object System.Windows.Forms.Label
$lblFilter.Text='Project:'; $lblFilter.Location='10,70'; $lblFilter.AutoSize=$true
$form.Controls.Add($lblFilter)

$cboProject = New-Object System.Windows.Forms.ComboBox
$cboProject.DropDownStyle='DropDownList'
$cboProject.Location='70,66'; $cboProject.Size='140,24'
$form.Controls.Add($cboProject)

# Queue List
$grpQ = New-Object System.Windows.Forms.GroupBox
$grpQ.Text='Queue (latest)'; $grpQ.Location='10,95'; $grpQ.Size='520,500'
$form.Controls.Add($grpQ)

$lvQ = New-Object System.Windows.Forms.ListView
$lvQ.View='Details'; $lvQ.FullRowSelect=$true; $lvQ.GridLines=$true; $lvQ.HideSelection=$false
$null = $lvQ.Columns.Add('Project',70)
$null = $lvQ.Columns.Add('Bot',90)
$null = $lvQ.Columns.Add('Name',260)
$null = $lvQ.Columns.Add('When',90)
$lvQ.Location='12,22'; $lvQ.Size='496,468'
$grpQ.Controls.Add($lvQ)

# Activity List
$grpA = New-Object System.Windows.Forms.GroupBox
$grpA.Text=("Activity (tail {0}) - {1}" -f $TailLines,$LogPath)
$grpA.Location='540,95'; $grpA.Size='500,500'
$form.Controls.Add($grpA)

$lvA = New-Object System.Windows.Forms.ListView
$lvA.View='Details'; $lvA.FullRowSelect=$true; $lvA.GridLines=$true; $lvA.HideSelection=$false
$null = $lvA.Columns.Add('When',120)
$null = $lvA.Columns.Add('Action',60)
$null = $lvA.Columns.Add('Project',70)
$null = $lvA.Columns.Add('Bot',80)
$null = $lvA.Columns.Add('Item',140)
$null = $lvA.Columns.Add('Run',80)
$null = $lvA.Columns.Add('Info',120)
$lvA.Location='12,22'; $lvA.Size='476,468'
$grpA.Controls.Add($lvA)

$tmr = New-Object System.Windows.Forms.Timer
$tmr.Interval = $RefreshMs

# State
$lastProjects = @('All')

function Refresh-Model {
  $status = Get-WatcherStatus
  $lblTop.Text = ("Watcher: {0} | Last Result: {1}`nNext: {2}`nLast: {3}" -f $status.Status,$status.LastResult,$status.NextRun,$status.LastRun)
  $lblMeta.Text = ("Auto-refresh: {0}s - Queue: {1}" -f ([math]::Round($RefreshMs/1000,0)), $Queue)

  $qItems = Get-QueueItems -Path $Queue -Top 250
  $aLines = Get-LogTail -Path $LogPath -Lines $TailLines
  $act    = @(Parse-Activity $aLines)

  $projects = @('All') + ($qItems.Project + $act.Project | Where-Object { $_ -and $_ -ne '-' } | Sort-Object -Unique)
  if ($projects -join ',' -ne $lastProjects -join ',') {
    $cboProject.Items.Clear()
    [void]$cboProject.Items.AddRange($projects)
    $cboProject.SelectedIndex = 0
    $lastProjects = $projects
  }

  $selProj = if ($cboProject.SelectedItem) { [string]$cboProject.SelectedItem } else { 'All' }

  $lvQ.BeginUpdate(); $lvQ.Items.Clear()
  foreach ($q in $qItems) {
    if ($selProj -ne 'All' -and $q.Project -ne $selProj) { continue }
    Add-LVRow $lvQ @([string]$q.Project,[string]$q.Bot,[string]$q.Name,[string]$q.WhenStr)
  }
  $lvQ.EndUpdate()

  $lvA.BeginUpdate(); $lvA.Items.Clear()
  foreach ($e in $act) {
    $projStr = [string]$e.Project
    if ($selProj -ne 'All' -and $projStr -and $projStr -ne $selProj) { continue }
    Add-LVRow $lvA @(
      [string]$e.When,
      [string]$e.Action,
      [string]$e.Project,
      [string]$e.Bot,
      [string]$e.Item,
      [string]$e.Run,
      [string]$e.Info
    )
  }
  $lvA.EndUpdate()
}

# Buttons
$btnRefresh.Add_Click({ Refresh-Model })
$btnOpenLog.Add_Click({ if (Test-Path $LogPath) { Start-Process notepad.exe $LogPath } })
$btnOpenQueue.Add_Click({ if (Test-Path $Queue) { Start-Process explorer.exe $Queue } })
$btnHC.Add_Click({
  $id = ('T-HEALTHCHECK-AZ-MONITOR-{0}' -f (Get-Date -AsUTC -Format 'yyyyMMdd-HHmmss'))
  $json = [ordered]@{
    id=$id; type='HEALTHCHECK'; project='AZ'; bot='Watcher';
    payload=@{ ts=(Get-Date -AsUTC -Format s); source='MonitorButton' }
  } | ConvertTo-Json -Depth 6
  New-Item -ItemType Directory -Force -Path $Queue | Out-Null
  $json | Set-Content -Path (Join-Path $Queue ($id + '.json')) -Encoding UTF8
})

$cboProject.add_SelectedIndexChanged({ Refresh-Model })
$tmr.Add_Tick({ Refresh-Model })
$tmr.Start()

Refresh-Model
[void]$form.ShowDialog()
