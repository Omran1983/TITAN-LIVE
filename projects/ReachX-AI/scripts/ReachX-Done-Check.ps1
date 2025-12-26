Param(
    [string]$ProjectRoot = "F:\ReachX-AI",
    [string]$UiRoot      = "F:\ReachX-AI\infra\ReachX-Workers-UI-v1"
)

$ErrorActionPreference = "Stop"
$errors = @()

function Add-CheckError {
    param([string]$Message)
    $script:errors += $Message
}

function Require-Path {
    param(
        [string]$Path,
        [string]$Message
    )
    if (-not (Test-Path $Path)) {
        Add-CheckError $Message
    }
}

function Require-Contains {
    param(
        [string]$FilePath,
        [string]$Needle,
        [string]$Message
    )
    if (Test-Path $FilePath) {
        $content = Get-Content -Path $FilePath -Raw
        if ($content -notlike "*$Needle*") {
            Add-CheckError $Message
        }
    }
}

Write-Host "=== ReachX Done Check (HTML only) ==="

# HTML files exist
Require-Path "$UiRoot\index.html"       "Missing index.html"
Require-Path "$UiRoot\dashboard.html"   "Missing dashboard.html"
Require-Path "$UiRoot\employers.html"   "Missing employers.html"
Require-Path "$UiRoot\workers.html"     "Missing workers.html"
Require-Path "$UiRoot\dormitories.html" "Missing dormitories.html"
Require-Path "$UiRoot\requests.html"    "Missing requests.html"
Require-Path "$UiRoot\invoices.html"    "Missing invoices.html"

# Root markers (IDs)
Require-Contains "$UiRoot\dashboard.html"   "reachx-dashboard-root"   "dashboard.html missing root div"
Require-Contains "$UiRoot\employers.html"   "reachx-employers-root"   "employers.html missing root div"
Require-Contains "$UiRoot\workers.html"     "reachx-workers-root"     "workers.html missing root div"
Require-Contains "$UiRoot\dormitories.html" "reachx-dorms-root"       "dormitories.html missing root div"
Require-Contains "$UiRoot\requests.html"    "reachx-requests-root"    "requests.html missing root div"
Require-Contains "$UiRoot\invoices.html"    "reachx-invoices-root"    "invoices.html missing root div"

# RESULT
if ($errors.Count -gt 0) {
    Write-Host "ReachX DONE CHECK: FAILED" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
    exit 1
} else {
    Write-Host "ReachX DONE CHECK: PASSED" -ForegroundColor Green
    exit 0
}
