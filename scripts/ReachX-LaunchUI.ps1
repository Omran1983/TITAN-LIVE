param(
    [string]$ProjectRoot = "F:\ReachX-AI"
)

Write-Host "Launching ReachX UI from '$ProjectRoot'..."

# Expected ReachX UI folder
$uiDir = Join-Path $ProjectRoot "infra\ReachX-Workers-UI-v1"

if (-not (Test-Path $uiDir)) {
    Write-Warning "ReachX UI folder not found at $uiDir. Skipping ReachX UI launch."
    return
}

$pkg = Join-Path $uiDir "package.json"
if (-not (Test-Path $pkg)) {
    Write-Warning "No package.json found at $pkg. ReachX UI app is not set up yet; skipping 'npm run dev'."
    return
}

Write-Host "Using ReachX UI directory: $uiDir"
Set-Location $uiDir

Write-Host "Starting ReachX UI dev server (npm run dev)..."
npm run dev
