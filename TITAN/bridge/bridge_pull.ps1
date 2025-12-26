param(
    [string]$FromFile = ""
)

$ErrorActionPreference = "Stop"

# Resolve TITAN root relative to this script
$BridgeDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TitanRoot = Resolve-Path (Join-Path $BridgeDir "..")  # TITAN/
$Inbox = Join-Path $TitanRoot "io\inbox"

New-Item -ItemType Directory -Force -Path $Inbox | Out-Null

function Get-JsonText {
    param([string]$FromFile)
    if ($FromFile -and (Test-Path $FromFile)) {
        return Get-Content -Raw -Encoding UTF8 $FromFile
    }
    return Get-Clipboard -Raw
}

$jsonText = Get-JsonText -FromFile $FromFile
if (-not $jsonText -or $jsonText.Trim().Length -lt 2) {
    Write-Host "❌ No JSON found. Copy task JSON to clipboard or pass -FromFile path." -ForegroundColor Red
    exit 1
}

# Validate JSON parse
try {
    $obj = $jsonText | ConvertFrom-Json -ErrorAction Stop
}
catch {
    Write-Host "❌ Invalid JSON. Fix payload then retry." -ForegroundColor Red
    exit 1
}

# Basic required fields
if (-not $obj.version -or -not $obj.task_id -or -not $obj.request -or -not $obj.limits) {
    Write-Host "❌ Schema fail: requires version, task_id, request, limits." -ForegroundColor Red
    exit 1
}

$taskId = $obj.task_id
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outName = "task_${taskId}_${stamp}.json"
$outPath = Join-Path $Inbox $outName


# Write UTF-8 (No BOM)
$utf8NoBom = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllText($outPath, $jsonText, $utf8NoBom)

Write-Host "✅ Task injected into inbox:" -ForegroundColor Green
Write-Host "   Path: $outPath"
Write-Host "   Size: $($jsonText.Length) chars"

