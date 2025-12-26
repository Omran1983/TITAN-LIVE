param(
    [string]$Remote = "origin"
)

# Ensure we're in a git repo
if (-not (Test-Path ".git")) {
    Write-Host "This directory is not a git repository." -ForegroundColor Red
    exit 1
}

# Check for uncommitted changes
$changes = git status --porcelain

if (-not [string]::IsNullOrWhiteSpace($changes)) {
    Write-Host "There are uncommitted changes. Push aborted." -ForegroundColor Yellow
    git status
    exit 1
}

# Fetch latest from remote
git fetch $Remote

# Get current branch name
$branch = git rev-parse --abbrev-ref HEAD

if ([string]::IsNullOrWhiteSpace($branch)) {
    Write-Host "Unable to determine current branch." -ForegroundColor Red
    exit 1
}

Write-Host "No local changes detected. Pushing $branch to $Remote..." -ForegroundColor Green
git push $Remote $branch
