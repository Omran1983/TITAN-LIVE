param(
    [string]$Message = ""
)

# === CONFIG ===
# Path to your website project
$repoPath = "C:\Users\ICL  ZAMBIA\Desktop\AOGRL-Website\aogrl-v3-updated"

# Git branch that GitHub uses
$branch  = "main"   # change to "master" if your repo uses master

# === SCRIPT ===
Write-Host "=== AOGRL Deploy ===" -ForegroundColor Cyan
Write-Host "Project: $repoPath"
Set-Location $repoPath

# Show current status
git status

if (-not $Message -or $Message.Trim() -eq "") {
    $Message = "chore: AOGRL site update $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
}

Write-Host "`nStaging changes..." -ForegroundColor Yellow
git add .

# If nothing to commit, just push (so GitHub Action can still run if needed)
$changes = git diff --cached
if ($changes) {
    Write-Host "Committing with message: $Message" -ForegroundColor Yellow
    git commit -m $Message
} else {
    Write-Host "No file changes staged. Skipping commit." -ForegroundColor DarkYellow
}

Write-Host "`nPushing to origin/$branch ..." -ForegroundColor Yellow
git push origin $branch

Write-Host "`nIf GitHub Action is configured, deployment to GoDaddy will start automatically." -ForegroundColor Green
Write-Host "=== Done ==="
