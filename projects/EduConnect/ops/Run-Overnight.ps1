Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Config
$Ref    = "drnqpbyptyyuacmrvdrr"
$SBURL  = "https://$Ref.supabase.co"
$Root   = "F:\EduConnect"
$LogDir = Join-Path $Root "logs"
$Secrets= Join-Path $Root "env\hq-lite.secrets"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$Stamp  = Get-Date -Format "yyyyMMdd_HHmmss"
$Log    = Join-Path $LogDir "overnight_$Stamp.log"
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

function Log { param([string]$m) $ts=(Get-Date -Format "yyyy-MM-dd HH:mm:ss"); "$ts $m" | Tee-Object -FilePath $Log -Append }

# --- Secrets (file + env fallback; no ternary)
if (-not (Test-Path $Secrets)) { throw "Missing secrets file: $Secrets" }
$S=@{}; Get-Content $Secrets | % {
  if ($_ -match '^\s*([^#=\s]+)\s*=\s*(.+?)\s*$') { $S[$matches[1]]=$matches[2].Trim('"').Trim("'") }
}
if (-not $S['SUPABASE_ANON_KEY']     -and $env:SUPABASE_ANON_KEY)     { $S['SUPABASE_ANON_KEY']     = $env:SUPABASE_ANON_KEY }
if (-not $S['SUPABASE_SERVICE_ROLE'] -and $env:SUPABASE_SERVICE_ROLE) { $S['SUPABASE_SERVICE_ROLE'] = $env:SUPABASE_SERVICE_ROLE }
if (-not $S['SUPABASE_ANON_KEY'])     { throw "Missing secret: SUPABASE_ANON_KEY" }
if (-not $S['SUPABASE_SERVICE_ROLE']) { throw "Missing secret: SUPABASE_SERVICE_ROLE" }
Log "Start | SBURL=$SBURL"

# --- Helper (no ternary)
function Invoke-Supa {
  param(
    [ValidateSet('GET','POST','PATCH','DELETE')] [string]$Method,
    [Parameter(Mandatory=$true)] [string]$Path,
    [hashtable]$Body,
    [ValidateSet('anon','service')] [string]$Auth = 'service'
  )
  $url = "$SBURL/rest/v1/$Path"
  if ($Auth -eq 'service') { $tok = $S['SUPABASE_SERVICE_ROLE'] } else { $tok = $S['SUPABASE_ANON_KEY'] }
  $hdr = @{ apikey=$tok; Authorization="Bearer $tok" }
  if ($Body) { $hdr['Content-Type']='application/json' }
  try {
    if ($Body) { return Invoke-RestMethod -Method $Method -Uri $url -Headers $hdr -Body ($Body | ConvertTo-Json -Depth 12) }
    else       { return Invoke-RestMethod -Method $Method -Uri $url -Headers $hdr }
  } catch { Log "HTTP ERROR $Method $Path -> $($_.Exception.Message)"; throw }
}

# --- 1) Pre stats
Log "Step 1: admin_stats (pre)"
$pre = Invoke-Supa -Method GET -Path 'admin_stats?select=*'
Log ("pre: " + ($pre|ConvertTo-Json -Depth 6))

# --- 2) Seed rows (SERVICE ROLE)
Log "Step 2: seed"
[void](Invoke-Supa -Method POST -Path 'rpc/add_task'  -Body @{ title="Overnight seed $Stamp"; details="Run-Overnight.ps1" } )
[void](Invoke-Supa -Method POST -Path 'rpc/add_error' -Body @{ severity="error"; context="overnight seed"; data=@{stamp=$Stamp; source="Run-Overnight.ps1"} } )

# --- 3) Final stats + summary
Log "Step 3: admin_stats (final)"
$final = Invoke-Supa -Method GET -Path 'admin_stats?select=*'
Log ("final: " + ($final|ConvertTo-Json -Depth 6))

[int]$errs = [int]$final.errors
[int]$tks  = [int]$final.tasks
$summary = @{ ok=$final.ok; now=$final.now; tasks=$tks; errors=$errs; note="Pass if tasks>=1 and errors>=1." } | ConvertTo-Json
Log ("SUMMARY: " + $summary)

if ($tks -lt 1 -or $errs -lt 1) { Log "FAIL"; exit 2 } else { Log "SUCCESS"; exit 0 }
