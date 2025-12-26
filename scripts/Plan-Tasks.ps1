param(
  [string]$Queue = "$env:AZ_HOME\bridge\file-queue",
  [string]$ConfigPath = "$env:AZ_HOME\configs\preflight.json",
  [int]$MaxTasks = 5
)
$ErrorActionPreference = "Stop"
if (-not $env:AZ_HOME) { $env:AZ_HOME = (Get-Location).Path }
$cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$model = $cfg.models.primary
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$planDir = Join-Path $env:AZ_HOME "logs\plans"
New-Item -ItemType Directory -Force -Path $planDir | Out-Null

$files = Get-ChildItem $Queue -Filter *.json | Select-Object -First $MaxTasks
if (-not $files) { Write-Host "No tasks in queue."; exit 0 }

foreach ($f in $files) {
  $task = Get-Content $f.FullName -Raw | ConvertFrom-Json
  $tid  = $task.task_id
  $goal = $task.goal
  $caps = $cfg.caps
  $sys = @"
You are AION-ZERO's planner. Output ONLY a concise action plan using this schema per line:
ACTION <tool> | ARG <argument> | THEN <expected observation>
Finish with one line: STOP <reason>.
Rules:
- Max $($caps.max_steps) steps.
- No code, no explanations outside schema.
- Tools allowed: BROWSER.GOTO, BROWSER.CLICK, BROWSER.TYPE, BROWSER.READ, BROWSER.SCREENSHOT, FILE.WRITE, HALT.
- Obey: OPEN-ACCESS mode; DO NOT submit payments or destructive ops.
"@

  $usr = "TASK-ID: $tid`nGOAL: $goal`nTIMEOUT: $($caps.timeout_s)s`nStart planning now."

  $body = @{
    model   = $model
    prompt  = "SYSTEM:\n$sys\n\nUSER:\n$usr"
    stream  = $false
    options = @{ temperature = 0.2; repeat_penalty = 1.05; num_ctx = 4096 }
  } | ConvertTo-Json -Depth 6

  try {
    $resp = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method POST -ContentType "application/json" -Body $body -TimeoutSec 120
    $plan = ($resp.response | Out-String).Trim()
  } catch {
    $plan = "ERROR: $_"
  }

  # basic schema validation
  $validLines = @()
  foreach ($line in ($plan -split "`r?`n")) {
    $L = $line.Trim()
    if ($L -match '^(ACTION\s+.+\s+\|\s+ARG\s+.*\s+\|\s+THEN\s+.+)$' -or $L -match '^(STOP\s+.+)$') {
      $validLines += $L
    }
  }
  if ($validLines.Count -eq 0) { $validLines = @("STOP Plan invalid or empty.") }

  $outPath = Join-Path $planDir "$($tid)-plan-$ts.txt"
  $header = "TASK $tid | GOAL: $goal`nMODEL: $model | STEPS<= $($caps.max_steps)`n---"
  ($header + "`n" + ($validLines -join "`n")) | Set-Content $outPath -Encoding UTF8
  Write-Host "Planned -> $outPath"
}
