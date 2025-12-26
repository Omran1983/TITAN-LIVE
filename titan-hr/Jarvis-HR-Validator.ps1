<#
    Jarvis-HR-Validator.ps1
    -----------------------
    Validates employee data against PRB-2026 rules.
    Outputs: Compliance Report (JSON/Markdown).
#>

param(
    [int]$CommandId = 0,
    [switch]$SingleRun,
    [string]$InputPath = "F:\AION-ZERO\titan-hr\employees_dummy.csv"
)

$ErrorActionPreference = "Stop"
. "F:\AION-ZERO\scripts\Jarvis-LoadEnv.ps1"
$SupabaseUrl = $env:SUPABASE_URL
$ServiceKey = $env:SUPABASE_SERVICE_ROLE_KEY
if (-not $ServiceKey) { $ServiceKey = $env:SUPABASE_SERVICE_KEY }

$Headers = @{ apikey = $ServiceKey; Authorization = "Bearer $ServiceKey"; "Content-Type" = "application/json" }

function Update-Command {
    param([int]$Id, [hashtable]$Fields)
    if ($Id -eq 0) { return }
    $body = $Fields | ConvertTo-Json -Depth 5
    Invoke-RestMethod -Method Patch -Uri "$SupabaseUrl/rest/v1/az_commands?id=eq.$Id" -Headers $Headers -Body $body | Out-Null
}

function Invoke-HRValidation {
    Write-Host ">>> TITAN-HR: Starting Compliance Validation..." -ForegroundColor Cyan

    # 1. Load Rules
    $rulesJson = Get-Content "F:\AION-ZERO\titan-hr\prb_rules.json" -Raw | ConvertFrom-Json
    $minSalary = $rulesJson.constants.min_salary_base
    Write-Host " -> Rule Loaded: Min Salary = Rs $minSalary" -ForegroundColor DarkGray

    # 2. Load Data
    if (-not (Test-Path $InputPath)) { throw "Input file not found: $InputPath" }
    $employees = Import-Csv $InputPath

    # 3. Validate
    $violations = @()
    $compliantCount = 0

    foreach ($emp in $employees) {
        $salary = [int]$emp.salary
        
        # Check Floor
        if ($salary -lt $minSalary) {
            $violations += @{
                id      = $emp.id
                name    = $emp.name
                issue   = "BELOW_MIN_WAGE"
                details = "Salary $salary < $minSalary"
            }
        }
        else {
            $compliantCount++
        }
    }

    # 4. Generate Report
    $score = if ($employees.Count -gt 0) { [math]::Round(($compliantCount / $employees.Count) * 100, 2) } else { 0 }
    
    $report = @{
        timestamp           = (Get-Date).ToString("o")
        total_employees     = $employees.Count
        compliant_employees = $compliantCount
        compliance_score    = $score
        violations          = $violations
        rules_version       = $rulesJson.meta.version
    }
    
    $reportJson = $report | ConvertTo-Json -Depth 5
    $color = if ($score -eq 100) { "Green" } else { "Red" }
    Write-Host " -> Validation Complete. Score: $score%" -ForegroundColor $color
    
    # Save Report Artifact
    $reportPath = "F:\AION-ZERO\titan-hr\compliance_report_$(Get-Date -Format 'yyyyMMdd').json"
    $reportJson | Set-Content $reportPath
    Write-Host " -> Report Saved: $reportPath"

    return $reportJson
}

# --- MAIN ---
try {
    if ($CommandId -gt 0) {
        Update-Command -Id $CommandId -Fields @{ status = "in_progress"; picked_at = (Get-Date).ToString("o") }
    }

    $result = Invoke-HRValidation
    
    if ($CommandId -gt 0) {
        Update-Command -Id $CommandId -Fields @{ 
            status      = "completed"
            result_json = $result
            updated_at  = (Get-Date).ToString("o")
        }
    }
}
catch {
    Write-Error "HR Validation Failed: $_"
    if ($CommandId -gt 0) {
        Update-Command -Id $CommandId -Fields @{ status = "error"; error_message = $_.Exception.Message }
    }
}
