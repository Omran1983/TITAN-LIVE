param (
    [string]$TargetDir = "C:\Users\ICL  ZAMBIA\Desktop\okasina-fashion-store-vite"
)

$SourceDir = $PSScriptRoot
$UncTarget = $TargetDir # Simple path

Write-Host "--- TITAN DEPLOYMENT SEQUENCE ---" -ForegroundColor Cyan
Write-Host "Source: $SourceDir"
Write-Host "Target: $UncTarget"

if (-not (Test-Path $UncTarget)) {
    Write-Error "Target directory does not exist: $UncTarget"
    exit 1
}

# 1. Create Directories
$AppsDir = Join-Path $UncTarget "apps"
$InspectorDir = Join-Path $AppsDir "inspector"
$DoctorDir = Join-Path $AppsDir "doctor"

New-Item -ItemType Directory -Force -Path $InspectorDir | Out-Null
New-Item -ItemType Directory -Force -Path $DoctorDir | Out-Null
Write-Host "[+] Created app directories" -ForegroundColor Green

# 2. Copy Inspector
Write-Host "[*] Copying Inspector..."
Copy-Item -Path "$SourceDir\apps\inspector\inspector.py" -Destination "$InspectorDir\inspector.py" -Force
# Create empty reports dir
New-Item -ItemType Directory -Force -Path "$InspectorDir\reports\latest" | Out-Null

# 3. Copy Doctor
Write-Host "[*] Copying Doctor..."
Copy-Item -Path "$SourceDir\apps\doctor\doctor.py" -Destination "$DoctorDir\doctor.py" -Force
Copy-Item -Recurse -Path "$SourceDir\apps\doctor\schemas" -Destination "$DoctorDir" -Force
# Create empty ledger
Set-Content -Path "$DoctorDir\ledger.jsonl" -Value "" -Force

# 4. Adapt Inspector for Vite (Port 5173)
Write-Host "[*] Configuring Inspector for OKASINA (Vite)..."
$InspFile = "$InspectorDir\inspector.py"
$InspContent = Get-Content $InspFile -Raw
# Replace Default URL
$InspContent = $InspContent -replace 'DEFAULT_BASE_URL = "http://localhost:8001"', 'DEFAULT_BASE_URL = "http://localhost:5173"'
# Replace Root Resolution (fallback is fine, but lets ensure env var name change if we want)
# Actually, the resolve_titan_root function uses parents[2], which still works if structure is apps/inspector/inspector.py
$InspContent | Set-Content $InspFile -Encoding UTF8

# 5. Adapt Doctor for Vite
Write-Host "[*] Configuring Doctor for OKASINA..."
$DocFile = "$DoctorDir\doctor.py"
$DocContent = Get-Content $DocFile -Raw
# Replace Restart Target -> package.json (Touching package.json usually triggers watcher)
$DocContent = $DocContent -replace 'bridge_api.py', 'package.json'
$DocContent = $DocContent -replace 'bridge/bridge_api.py', 'package.json' 
# Just looking for the string in variable definitions
$DocContent = $DocContent -replace 'TITAN_ROOT / "bridge" / "bridge_api.py"', 'TITAN_ROOT / "package.json"'
# Rename Env Var lookup
$DocContent = $DocContent -replace '"TITAN_ROOT"', '"OKASINA_ROOT"'
$DocContent | Set-Content $DocFile -Encoding UTF8

Write-Host "--- DEPLOYMENT COMPLETE ---" -ForegroundColor Green
Write-Host "To run Inspector: python apps/inspector/inspector.py --mode crawl"
Write-Host "To run Doctor:    python apps/doctor/doctor.py"
