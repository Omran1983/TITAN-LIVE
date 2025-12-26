<#
.SYNOPSIS
    Imports legacy projects and external folders into the AION-ZERO Monorepo.
    This enables the AI Agent (Citadel) to access, scan, and manage them.

.DESCRIPTION
    1. Copies Okasina from Desktop -> F:\AION-ZERO\products\okasina-fashion-store-vite
    2. Copies F:\* folders -> F:\AION-ZERO\universe\*
    
    WARNING: This operation copies files. Ensure you have disk space.
    Use -Move switch to Move instead of Copy (Destructive source).
#>

Param(
    [Switch]$Move = $false
)

$DestRoot = "F:\AION-ZERO"
$Universe = "$DestRoot\universe"
$Products = "$DestRoot\products"

# Ensure Destinations
New-Item -ItemType Directory -Force -Path $Universe | Out-Null
New-Item -ItemType Directory -Force -Path $Products | Out-Null

Write-Host ">>> STARTING EMPIRE CONSOLIDATION <<<" -ForegroundColor Cyan

# 1. OKASINA (Special Case: From Desktop)
$OkasinaSource = "C:\Users\ICL  ZAMBIA\Desktop\okasina-fashion-store-vite"
$OkasinaDest = "$Products\okasina-fashion-store-vite"
if (Test-Path $OkasinaSource) {
    Write-Host "Importing Okasina from Desktop..." -ForegroundColor Yellow
    Copy-Item -Path $OkasinaSource -Destination $OkasinaDest -Recurse -Force
    Write-Host "OKASINA Imported." -ForegroundColor Green
}
else {
    Write-Host "WARNING: Okasina not found at $OkasinaSource" -ForegroundColor Red
}

# 2. THE LIST (From F:\ Root)
$Targets = @(
    "F:\.pnpm-store",
    "F:\_Consolidated",
    "F:\_Ops",
    "F:\Antigravity",
    "F:\AOGRL-DS",
    "F:\Archive",
    "F:\autopilot",
    "F:\Backups",
    "F:\ComfyUI",
    "F:\delivery_crm",
    "F:\Dev",
    "F:\EduConnect",
    "F:\Jarvis",
    "F:\Jarvis-Desktop-Agent",
    "F:\Jarvis-LocalOps",
    "F:\Jules Trading Platform",
    "F:\Logs",
    "F:\OllamaData",
    "F:\PowerShell",
    "F:\ReachX-AI",
    "F:\ReachX-Pilot-Project",
    "F:\Releases",
    "F:\secrets",
    "F:\tweakops",
    "F:\Workspaces"
)

foreach ($Path in $Targets) {
    if (Test-Path $Path) {
        $Name = Split-Path $Path -Leaf
        $TargetDest = "$Universe\$Name"
        
        Write-Host "Processing: $Name..." -ForegroundColor Cyan
        
        # Check if already exists
        if (Test-Path $TargetDest) {
            Write-Host "  -> Exists in Universe. Skipping (use manual overwrite if needed)." -ForegroundColor DarkGray
        }
        else {
            Write-Host "  -> Copying to $TargetDest..." -ForegroundColor Yellow
            try {
                if ($Move) {
                    Move-Item -Path $Path -Destination $TargetDest -Force -ErrorAction Stop
                }
                else {
                    Copy-Item -Path $Path -Destination $TargetDest -Recurse -Force -ErrorAction Stop
                }
                Write-Host "  -> SUCCESS" -ForegroundColor Green
            }
            catch {
                Write-Host "  -> ERROR: $_" -ForegroundColor Red
            }
        }
    }
    else {
        Write-Host "Skipping missing source: $Path" -ForegroundColor DarkGray
    }
}

Write-Host ">>> CONSOLIDATION COMPLETE <<<" -ForegroundColor Cyan
Write-Host "New location: F:\AION-ZERO\universe" -ForegroundColor Cyan
