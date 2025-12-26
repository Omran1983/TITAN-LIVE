<# 
    Jarvis-RunMissionStep.ps1
    -------------------------
    Executes a concrete mission step by code.

    Currently implemented steps for AOGRL-DS bootstrap:

      - clone-template :
          Copy OKASINA project into AOGRL-DS folder (read-only on source)

      - rename-project :
          Rename project metadata inside the cloned folder for AOGRL-DS

      - wire-services :
          Prepare env template for new Supabase/Vercel setup
          Rewire git remote to the AOGRL-DS GitHub org

      - test-and-deploy :
          Run npm install (if needed), lint, build
          Optionally deploy via Vercel when AOGRL_DS_AUTODEPLOY=1

    NOTE:
      - This script ONLY works on the AOGRL-DS clone at:
          F:\AOGRL-DS\okasina-fashion-store-vite
      - It does NOT modify the original OKASINA project under C:\.
#>

param(
    [Parameter(Mandatory = $true)]
    [int]$MissionId,

    [Parameter(Mandatory = $true)]
    [string]$StepCode
)

$ErrorActionPreference = "Stop"

# Centralized project root for the AOGRL-DS clone
$AogrlDsRoot = "F:\AOGRL-DS\okasina-fashion-store-vite"

function Assert-ProjectRootExists {
    param(
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "AOGRL-DS project root not found at: $Path"
    }
}

try {
    # Resolve paths
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $rootDir   = Split-Path -Parent $scriptDir

    # Load env if helper exists (keeps it consistent with the rest of Jarvis)
    $loadEnv = Join-Path $scriptDir "Jarvis-LoadEnv.ps1"
    if (Test-Path $loadEnv) {
        & $loadEnv | Out-Null
    }

    Write-Host "=== Jarvis-RunMissionStep ==="
    Write-Host "MissionId = $MissionId"
    Write-Host "StepCode  = $StepCode"
    Write-Host ""

    switch ($StepCode.ToLower()) {

        # -------------------------------------------------------------
        # STEP 1: CLONE TEMPLATE
        # -------------------------------------------------------------
        "clone-template" {
            # Source: existing OKASINA Vite project on C:\
            $sourcePath = "C:\Users\ICL  ZAMBIA\Desktop\okasina-fashion-store-vite"

            # Destination root: new AOGRL-DS project folder on F:\
            $destRoot        = "F:\AOGRL-DS"
            $destFolderName  = "okasina-fashion-store-vite"
            $destPath        = Join-Path $destRoot $destFolderName

            Write-Host "Source      : $sourcePath"
            Write-Host "Destination : $destPath"
            Write-Host ""

            if (-not (Test-Path $sourcePath)) {
                throw "Source folder not found: $sourcePath"
            }

            # Create destination root if needed
            if (-not (Test-Path $destRoot)) {
                Write-Host "Creating destination root: $destRoot"
                New-Item -ItemType Directory -Path $destRoot | Out-Null
            }

            # Safety: do NOT overwrite an existing cloned folder
            if (Test-Path $destPath) {
                Write-Warning "Destination already exists: $destPath"
                Write-Warning "clone-template step is aborting to avoid overwrite."
                break
            }

            Write-Host "Copying files... this may take a moment."
            Copy-Item -Path $sourcePath -Destination $destRoot -Recurse -Force

            Write-Host ""
            Write-Host "OK - Cloned OKASINA template from:"
            Write-Host "  $sourcePath"
            Write-Host "to:"
            Write-Host "  $destPath"
            Write-Host ""
            Write-Host "No changes were made to the original OKASINA folder."
        }

        # -------------------------------------------------------------
        # STEP 2: RENAME PROJECT
        # -------------------------------------------------------------
        "rename-project" {
            Assert-ProjectRootExists -Path $AogrlDsRoot

            Write-Host "Renaming project metadata inside:"
            Write-Host "  $AogrlDsRoot"
            Write-Host ""

            # 1) Update package.json name/description
            $packageJsonPath = Join-Path $AogrlDsRoot "package.json"
            if (-not (Test-Path $packageJsonPath)) {
                Write-Host "package.json not found at $packageJsonPath. Skipping package rename." -ForegroundColor Yellow
            }
            else {
                Write-Host "Updating package.json..."
                $packageRaw = Get-Content $packageJsonPath -Raw
                $package    = $packageRaw | ConvertFrom-Json

                # New name / description for AOGRL-DS
                $newName        = "aogrl-ds-autopilot"
                $newDescription = "AOGRL-DS Autopilot storefront cloned from OKASINA."

                $package.name = $newName

                if ($package.PSObject.Properties.Name -contains "description" -and $package.description) {
                    $package.description = $newDescription + " " + $package.description
                }
                else {
                    $package | Add-Member -NotePropertyName "description" -NotePropertyValue $newDescription -Force
                }

                $package | ConvertTo-Json -Depth 10 | Set-Content -Path $packageJsonPath -Encoding UTF8
                Write-Host "  - package.json updated (name=$newName)"
            }

            Write-Host ""
            Write-Host "rename-project step completed (core metadata updated)."
        }

        # -------------------------------------------------------------
        # STEP 3: WIRE SERVICES (Supabase/Vercel/GitHub templates)
        # -------------------------------------------------------------
        "wire-services" {
            Assert-ProjectRootExists -Path $AogrlDsRoot

            Write-Host "Wiring service templates for AOGRL-DS in:"
            Write-Host "  $AogrlDsRoot"
            Write-Host ""

            # 3.1) Create env template file for AOGRL-DS
            $envTemplatePath = Join-Path $AogrlDsRoot ".env.aogrl-ds.template"

            $envTemplateContent = @"
# ============================================================
# AOGRL-DS Autopilot - Environment Template
# ============================================================
# Fill these values from your new Supabase / Vercel / Facebook / etc.
# This file is a template only. Copy it to .env.local when ready.
#
# Supabase (AOGRL-DS project: sotmvxhjupfhonqrtwik)
# ------------------------------------------------------------
# Example URL pattern (check your Supabase dashboard to confirm):
#   https://<project-ref>.supabase.co
#
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=

SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=

# Vercel / Deployment
# ------------------------------------------------------------
# VERCEL_ENV=production
# VERCEL_PROJECT_NAME=aogrl-ds-autopilot
# VERCEL_ORG=aogrl-dss-projects

# Facebook / Social / Other integrations
# ------------------------------------------------------------
# FACEBOOK_PAGE_ID=
# FACEBOOK_ACCESS_TOKEN=
# INSTAGRAM_BUSINESS_ID=
# INSTAGRAM_ACCESS_TOKEN=

# Any other AOGRL-DS specific configs go here.
"@

            Set-Content -Path $envTemplatePath -Value $envTemplateContent -Encoding UTF8
            Write-Host "  - Created env template: $envTemplatePath"

            # 3.2) Wire GitHub remote to AOGRL-DS org
            $gitFolder = Join-Path $AogrlDsRoot ".git"
            if (-not (Test-Path $gitFolder)) {
                Write-Host "No .git folder at $gitFolder. Skipping git remote wiring." -ForegroundColor Yellow
            }
            else {
                $newRemoteUrl = "https://github.com/AOGRL-DS/aogrl-ds-autopilot.git"
                Write-Host "Configuring git remote 'origin' -> $newRemoteUrl"

                Push-Location $AogrlDsRoot
                try {
                    $gitAvailable = $true
                    try {
                        git --version | Out-Null
                    }
                    catch {
                        $gitAvailable = $false
                    }

                    if (-not $gitAvailable) {
                        Write-Host "Git is not available on PATH. Skipping git remote wiring." -ForegroundColor Yellow
                    }
                    else {
                        # Remove existing origin if present
                        $existingRemotes = git remote 2>$null
                        if ($existingRemotes -contains "origin") {
                            git remote remove origin | Out-Null
                        }

                        git remote add origin $newRemoteUrl | Out-Null
                        Write-Host "  - git remote 'origin' now points to:"
                        Write-Host "    $newRemoteUrl"
                        Write-Host "    (Create the repo later on GitHub under the AOGRL-DS org if needed.)"
                    }
                }
                finally {
                    Pop-Location
                }
            }

            Write-Host ""
            Write-Host "wire-services step completed (env template + git remote)."
        }

        # -------------------------------------------------------------
        # STEP 4: TEST AND DEPLOY
        # -------------------------------------------------------------
        "test-and-deploy" {
            Assert-ProjectRootExists -Path $AogrlDsRoot

            Write-Host "Running tests and (optionally) deploy for AOGRL-DS in:"
            Write-Host "  $AogrlDsRoot"
            Write-Host ""

            Push-Location $AogrlDsRoot
            try {
                # 4.1) npm install (only if node_modules missing)
                $nodeModulesPath = Join-Path $AogrlDsRoot "node_modules"
                if (-not (Test-Path $nodeModulesPath)) {
                    Write-Host "node_modules not found. Running 'npm install'..."
                    npm install
                    Write-Host "npm install completed."
                }
                else {
                    Write-Host "node_modules exists. Skipping 'npm install'."
                }

                # 4.2) npm run lint
                Write-Host ""
                Write-Host "Running 'npm run lint'..."
                npm run lint
                Write-Host "'npm run lint' completed successfully."

                # 4.3) npm run build
                Write-Host ""
                Write-Host "Running 'npm run build'..."
                npm run build
                Write-Host "'npm run build' completed successfully."

                # 4.4) Optional Vercel deploy (guarded by env flag)
                Write-Host ""
                $autoDeployFlag = $env:AOGRL_DS_AUTODEPLOY
                if ($autoDeployFlag -eq "1") {
                    Write-Host "AOGRL_DS_AUTODEPLOY=1 detected. Attempting Vercel deployment..."

                    $vercelAvailable = $true
                    try {
                        vercel --version | Out-Null
                    }
                    catch {
                        $vercelAvailable = $false
                    }

                    if (-not $vercelAvailable) {
                        Write-Host "Vercel CLI not available on PATH. Skipping deploy." -ForegroundColor Yellow
                    }
                    else {
                        # You can adjust scope/project if your Vercel setup uses different names
                        $vercelArgs = @(
                            "--prod"
                        )

                        if ($env:VERCEL_ORG) {
                            $vercelArgs += @("--scope", $env:VERCEL_ORG)
                        }

                        if ($env:VERCEL_PROJECT_NAME) {
                            $vercelArgs += @("--project", $env:VERCEL_PROJECT_NAME)
                        }

                        Write-Host "Running: vercel $($vercelArgs -join ' ')"
                        vercel @vercelArgs
                        Write-Host "Vercel deployment command finished."
                    }
                }
                else {
                    Write-Host "AOGRL_DS_AUTODEPLOY is not set to '1'."
                    Write-Host "Skipping Vercel deploy step (lint + build still ran)."
                }
            }
            finally {
                Pop-Location
            }

            Write-Host ""
            Write-Host "test-and-deploy step completed (lint/build done, deploy conditional)."
        }

        # -------------------------------------------------------------
        # UNKNOWN STEP
        # -------------------------------------------------------------
        default {
            throw "Unknown StepCode '$StepCode'. Supported: clone-template, rename-project, wire-services, test-and-deploy."
        }
    }

    Write-Host ""
    Write-Host "=== Jarvis-RunMissionStep complete ==="
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
