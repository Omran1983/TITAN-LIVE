$ErrorActionPreference = "Stop"

$eduRoot      = "F:\EduConnect"
$workerRoot   = Join-Path $eduRoot "cloud\hq-lite-worker"
$srcDir       = Join-Path $workerRoot "src"

if (-not (Test-Path $workerRoot)) {
    Write-Host "EduConnect Worker root not found: $workerRoot" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Path $srcDir -Force | Out-Null

$statusModulePath = Join-Path $srcDir "status-module.js"

$statusJs = @"
export async function handleStatusRequest(env) {
  const now = new Date().toISOString();
  const supabaseUrl = env.SUPABASE_URL || 'missing';

  const body = {
    service: 'educonnect-hq-lite',
    time: now,
    supabaseUrlConfigured: supabaseUrl !== 'missing',
    supabaseUrl,
  };

  return new Response(JSON.stringify(body, null, 2), {
    status: 200,
    headers: {
      'content-type': 'application/json; charset=utf-8',
    },
  });
}
"@

Set-Content -Path $statusModulePath -Value $statusJs -Encoding UTF8

$logDir     = "F:\AION-ZERO\logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$eduJournal = Join-Path $logDir "educonnect-build-journal.md"

$entry = @"
## EduConnect Build (Status Module) $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Files updated:
- $statusModulePath

Notes:
- Adds handleStatusRequest(env) helper for Worker to return JSON status and SUPABASE_URL info.
- Next step: import and wire into main Worker router (src/index.js) on /status route.
"@

Add-Content -Path $eduJournal -Value $entry

Write-Host "EduConnect status module build completed." -ForegroundColor Green
Write-Host "  Status module: $statusModulePath" -ForegroundColor Green
