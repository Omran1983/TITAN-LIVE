[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Prompt
)

# ==== CONFIG ====
$Model     = "llama3.2:1b"   # Tiny model that fits your machine
$OllamaUrl = "http://localhost:11434/api/generate"
# ================

Write-Host ""
Write-Host "az code -> sending to Ollama (/api/generate)..." -ForegroundColor Cyan
Write-Host "Task: $Prompt" -ForegroundColor Yellow
Write-Host ""

# Build single prompt (system + user) for /api/generate
$fullPrompt = @"
You are a senior DevOps + Git + PowerShell automation assistant.

ALWAYS:
- Output ONLY a single PowerShell script.
- NO explanations, NO comments, NO markdown, NO code fences.
- The script should:
  - Operate on the CURRENT git repository ('.').
  - Be idempotent and safe.
  - Exit gracefully with error messages on failure.

User task:
$Prompt
"@

$body = @{
    model   = $Model
    prompt  = $fullPrompt
    stream  = $false
} | ConvertTo-Json -Depth 5

try {
    $response = Invoke-RestMethod -Uri $OllamaUrl -Method Post -Body $body -ContentType "application/json"
} catch {
    Write-Host "Error calling Ollama API:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

if (-not $response -or -not $response.response) {
    Write-Host "No content returned from model." -ForegroundColor Red
    exit 1
}

$scriptText = $response.response.Trim()

Write-Host "========= SUGGESTED POWERSHELL SCRIPT =========" -ForegroundColor Cyan
Write-Host ""
Write-Host $scriptText
Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan

$choice = Read-Host "Save & run this script? (y/n)"
if ($choice -ne 'y') {
    Write-Host "Aborted by user." -ForegroundColor DarkYellow
    exit 0
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$tempFile  = Join-Path $env:TEMP "az_code_$timestamp.ps1"

$scriptText | Out-File -FilePath $tempFile -Encoding utf8 -Force

Write-Host "Saved to: $tempFile" -ForegroundColor Yellow
Write-Host "Running script..." -ForegroundColor Green
Write-Host ""

try {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tempFile
} catch {
    Write-Host "Error while executing generated script:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
