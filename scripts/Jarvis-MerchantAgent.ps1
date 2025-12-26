<#
    Jarvis-MerchantAgent.ps1
    ------------------------
    The "Dropshipping Empire" Manager.
    
    Role:
    1. Watch "F:\AION-ZERO\inputs\products" for new images.
    2. Invoke Node.js Vision AI (Okasina module) to analyze them.
    3. List them as drafted products in Supabase.
    4. Log run to az_agent_runs.
#>

$ErrorActionPreference = "Stop"

# --- Configuration ---
$Project = "AOGRL-DS-Autopilot"
$AgentName = "Jarvis-MerchantAgent"
$InputsDir = "F:\AION-ZERO\inputs\products"
$ProcessedDir = "F:\AION-ZERO\inputs\products\processed"
$VisionScript = "F:\AION-ZERO\universe\AOGRL-DS\okasina-fashion-store-vite\scripts\analyze-local.js"
$NodeExe = "node"

# --- Setup ---
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptDir\Jarvis-LoadEnv.ps1" | Out-Null

if (-not (Test-Path $InputsDir)) {
    New-Item -ItemType Directory -Path $InputsDir -Force | Out-Null
    Write-Host "Created input directory: $InputsDir" -ForegroundColor Cyan
}
if (-not (Test-Path $ProcessedDir)) {
    New-Item -ItemType Directory -Path $ProcessedDir -Force | Out-Null
}

# --- Supabase Helper (Embedded for self-containment) ---
function Write-AgentRun {
    param($Status, $Severity, $Payload)
    
    $body = @{
        run_id      = [guid]::NewGuid()
        agent_name  = $AgentName
        status      = $Status
        severity    = $Severity
        payload     = $Payload
        started_at  = (Get-Date).ToUniversalTime().ToString("o")
        finished_at = (Get-Date).ToUniversalTime().ToString("o")
    } | ConvertTo-Json -Depth 5

    $url = "$env:SUPABASE_URL/rest/v1/az_agent_runs"
    $headers = @{
        "apikey"        = $env:SUPABASE_SERVICE_ROLE_KEY
        "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
        "Content-Type"  = "application/json"
        "Prefer"        = "return=minimal"
    }
    
    try {
        Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body | Out-Null
        Write-Host "[$AgentName] Logged run ($Status)." -ForegroundColor Gray
    }
    catch {
        Write-Warning "Failed to log to Supabase: $($_.Exception.Message)"
    }
}

# --- Main Logic ---

Write-Host "=== $AgentName Started ===" -ForegroundColor Cyan

# 1. Scan for Images
$images = Get-ChildItem -Path $InputsDir -Filter "*.*" | Where-Object { $_.Extension -match "\.(jpg|jpeg|png|webp)$" }

if ($images.Count -eq 0) {
    Write-Host "No new images in $InputsDir. Sleeping."
    Write-AgentRun "success" "info" @{ message = "Idle. No images found." }
    exit 0
}

Write-Host "Found $($images.Count) images to process." -ForegroundColor Yellow

$processedCount = 0
$results = @()

foreach ($img in $images) {
    Write-Host "Analying: $($img.Name)..." -ForegroundColor Cyan
    
    # 2. Call Vision AI
    $visionScriptPath = $VisionScript
    
    Write-Host "  -> Sending to Vision Brain..." -ForegroundColor DarkGray
    
    try {
        $jsonOutput = & $NodeExe $visionScriptPath $img.FullName
        $parsed = $jsonOutput | ConvertFrom-Json
        
        if ($parsed.success) {
            Write-Host "  -> Vision Success! Identified: $($parsed.data.name)" -ForegroundColor Green
            
            # 3. Call DB Insert
            Write-Host "  -> Saving to AOGRL-DS Database..." -ForegroundColor DarkGray
            
            # Save raw data payload to temp file
            $productData = $parsed.data | ConvertTo-Json -Depth 5
            $tempJson = "$ProcessedDir\$($img.BaseName).json"
            $productData | Set-Content -Path $tempJson -Encoding utf8
            
            # Execute DB Insert
            try {
                $dbJson = & $NodeExe $InsertScript $tempJson $img.FullName
                $dbParsed = $dbJson | ConvertFrom-Json
                
                if ($dbParsed.success) {
                    Write-Host "  -> Database Insert Success! ID: $($dbParsed.product.id)" -ForegroundColor Green
                    $results += @{
                        file    = $img.Name
                        product = $parsed.data
                        db_id   = $dbParsed.product.id
                        status  = "drafted"
                    }
                }
                else {
                    Write-Warning "  -> DB Insert Failed: $($dbParsed.error)"
                    $results += @{
                        file   = $img.Name
                        error  = "DB: $($dbParsed.error)"
                        status = "analyzed_only"
                    }
                }
            }
            catch {
                Write-Warning "  -> DB Script Error: $_"
                $results += @{
                    file   = $img.Name
                    error  = "DB Script: $_"
                    status = "analyzed_only"
                }
            }
            
            # Cleanup temp
            if (Test-Path $tempJson) { Remove-Item $tempJson }
        }
        else {
            Write-Warning "  -> Vision Error: $($parsed.error)"
            $results += @{
                file   = $img.Name
                error  = $parsed.error
                status = "failed"
            }
        }
    }
    catch {
        Write-Warning "  -> Script Execution Error: $_"
        $results += @{
            file   = $img.Name
            error  = "$_"
            status = "failed"
        }
    }

    # Move to processed
    Move-Item -Path $img.FullName -Destination $ProcessedDir -Force
    $processedCount++
}

# 3. Report
$payload = @{
    processed_count = $processedCount
    details         = $results
}

Write-Host "Job Complete. Processed $processedCount images." -ForegroundColor Green
Write-AgentRun "success" "info" $payload
