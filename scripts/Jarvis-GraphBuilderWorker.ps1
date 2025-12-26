<#
    Jarvis-GraphBuilderWorker.ps1
    -----------------------------
    Offline worker that rebuilds the Knowledge Graph.
    Should be scheduled to run every 6-12 hours.
#>

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\Jarvis-LoadEnv.ps1"

$BuilderScript = "F:\AION-ZERO\py\graph_builder.py"
$LogFile = "$ScriptDir\Jarvis-GraphBuilder.log"

function Write-Log {
    param($Msg)
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$ts $Msg" | Out-File -FilePath $LogFile -Append
    Write-Host "$ts $Msg"
}

Write-Log "=== STARTING GRAPH REBUILD ==="

if (-not (Test-Path $BuilderScript)) {
    Write-Log "[ERROR] Builder script not found at $BuilderScript"
    exit 1
}

try {
    # Check for python
    # We assume 'python' is in PATH. If using specific venv, adjust here.
    $pyVer = python --version 2>&1
    Write-Log "[INFO] Using $pyVer"

    # Check for git (Required for external ingestion)
    try {
        $gitVer = git --version 2>&1
        Write-Log "[INFO] Using $gitVer"
    }
    catch {
        Write-Log "[WARNING] Git not found. External ingestion will fail."
    }

    # RUN
    # Use Invoke-Expression or Start-Process to capture output
    # Passing env vars expressly just in case
    $env:SUPABASE_URL = $env:SUPABASE_URL
    $env:SUPABASE_SERVICE_ROLE_KEY = $env:SUPABASE_SERVICE_ROLE_KEY

    Write-Log "[INFO] Executing builder..."
    python $BuilderScript --root "F:\AION-ZERO" | Out-File -FilePath $LogFile -Append
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "[SUCCESS] Graph rebuild complete."
    }
    else {
        Write-Log "[FAIL] Python exited with code $LASTEXITCODE"
    }

}
catch {
    Write-Log "[CRITICAL] $($_.Exception.Message)"
}

Write-Log "=== END ==="
