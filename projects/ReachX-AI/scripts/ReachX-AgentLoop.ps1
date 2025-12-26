# ReachX-AgentLoop.ps1
# Autonomous dev agent for ReachX-AI
# - Reads F:\ReachX-AI\agent-task.json
# - If status == "queued":
#     * Calls Ollama to rewrite the target file
#     * Writes new content
#     * Marks task as "done"

$ErrorActionPreference = "Stop"

$taskPath = "F:\ReachX-AI\agent-task.json"

if (-not (Test-Path $taskPath)) {
    Write-Host "No task file found at $taskPath" -ForegroundColor Yellow
    exit 0
}

$taskJson = Get-Content -Path $taskPath -Raw | ConvertFrom-Json

if ($taskJson.status -ne "queued") {
    Write-Host "No queued task (status = $($taskJson.status)). Nothing to do." -ForegroundColor Yellow
    exit 0
}

# Resolve file path
$projectRoot = "F:\ReachX-AI"
$fileRel     = $taskJson.file
$filePath    = Join-Path $projectRoot $fileRel

if (-not (Test-Path $filePath)) {
    Write-Host "Target file not found: $filePath" -ForegroundColor Red
    exit 1
}

Write-Host "=== ReachX Agent Loop ===" -ForegroundColor Cyan
Write-Host "Task id : $($taskJson.id)"
Write-Host "File    : $filePath"
Write-Host "Goal    : $($taskJson.goal)"

$currentContent = Get-Content -Path $filePath -Raw

# ---------------------------------------------------------------------
# MODEL SELECTION
# ---------------------------------------------------------------------
$model = $env:REACHX_AGENT_MODEL
if (-not $model -or -not $model.Trim()) {
    $model = "llama3.2:1b"
}
Write-Host "Using Ollama model: $model" -ForegroundColor Yellow

# Build prompt for Ollama
$prompt = @"
You are an autonomous coding agent working on the ReachX-AI project on Windows.

PROJECT RULES:
- Only modify the SINGLE file specified.
- Keep paths and Supabase URLs compatible with the existing ReachX-AI setup.
- Do NOT invent new environment variables or secrets.
- Output MUST be valid JSON only, no markdown, no comments.

TASK:
- Goal: $($taskJson.goal)
- Extra notes: $($taskJson.notes)

CURRENT FILE CONTENT (full file, between the markers):

<<<FILE_START
$currentContent
FILE_END>>>

RESPONSE FORMAT (STRICT):
Return ONLY a single JSON object like:
{
  "new_content": "<the full new file content as a single string>"
}

Do NOT wrap in markdown.
Do NOT add extra fields.
"@

Write-Host "Calling Ollama..." -ForegroundColor Yellow

# Call Ollama (no -ngl, your build doesn’t support it)
$ollamaArgs   = @('run', $model, $prompt)
$ollamaOutput = & ollama @ollamaArgs 2>&1
$exitCode     = $LASTEXITCODE

if ($exitCode -ne 0) {
    Write-Host "Ollama returned non-zero exit code ($exitCode)." -ForegroundColor Red
    Write-Host "Raw output from Ollama:" -ForegroundColor DarkGray
    $ollamaOutput | Out-String | Write-Host
    exit 1
}

if (-not $ollamaOutput) {
    Write-Host "Ollama returned empty output." -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------
# NORMALISE OLLAMA OUTPUT TO STRING
# ---------------------------------------------------------------------
$ollamaText = $ollamaOutput | Out-String
$ollamaText = $ollamaText.Trim()

if (-not $ollamaText) {
    Write-Host "Ollama output is empty after normalisation." -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------
# EXTRACT JSON BLOCK
# ---------------------------------------------------------------------
$firstBrace = $ollamaText.IndexOf("{")
$lastBrace  = $ollamaText.LastIndexOf("}")

if ($firstBrace -lt 0 -or $lastBrace -le $firstBrace) {
    Write-Host "Could not find JSON braces in Ollama output." -ForegroundColor Red
    Write-Host "Raw output:" -ForegroundColor DarkGray
    Write-Host $ollamaText
    exit 1
}

$jsonText = $ollamaText.Substring($firstBrace, $lastBrace - $firstBrace + 1)

try {
    $result = $jsonText | ConvertFrom-Json
}
catch {
    Write-Host "Failed to parse Ollama JSON output." -ForegroundColor Red
    Write-Host "JSON candidate:" -ForegroundColor DarkGray
    Write-Host $jsonText
    exit 1
}

if (-not $result.new_content) {
    Write-Host "Ollama JSON did not contain 'new_content'." -ForegroundColor Red
    exit 1
}

# Backup old file
$backupPath = "$filePath.bak_$(Get-Date -Format "yyyyMMddHHmmss")"
Copy-Item -Path $filePath -Destination $backupPath -Force

# Write new content
Set-Content -Path $filePath -Value $result.new_content -Encoding utf8

Write-Host "File updated: $filePath" -ForegroundColor Green
Write-Host "Backup saved at: $backupPath" -ForegroundColor DarkGray

# Mark task as done
$taskJson.status       = "done"
$taskJson.completed_at = (Get-Date).ToString("o")

$taskJson | ConvertTo-Json -Depth 10 | Set-Content -Path $taskPath -Encoding utf8

Write-Host "Task $($taskJson.id) marked as done." -ForegroundColor Green
