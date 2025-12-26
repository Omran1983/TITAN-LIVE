$root = "F:\ReachX-AI"

$files = @(
    "reachx-hq.html",
    "reachx-dashboard-v2.html",
    "reachx-employers-dashboard.html",
    "reachx-workers-dashboard.html"
)

foreach ($f in $files) {
    $path = Join-Path $root $f
    if (Test-Path $path) {
        Write-Host "Opening $path"
        start $path
    } else {
        Write-Warning "Missing: $path"
    }
}
