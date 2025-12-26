$ErrorActionPreference = 'Continue'

# Where to put reports
$reportRoot = 'F:\AION-ZERO\reports'
if (-not (Test-Path $reportRoot)) {
    New-Item -ItemType Directory -Path $reportRoot -Force | Out-Null
}

$timestamp  = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$reportPath = Join-Path $reportRoot "night-report-$timestamp.txt"

"Night report $timestamp" | Out-File -FilePath $reportPath -Encoding UTF8
"==============================================" | Out-File -FilePath $reportPath -Append

# Key projects to scan
$projects = @(
    @{ Name = 'AION-ZERO';      Path = 'F:\AION-ZERO' },
    @{ Name = 'ReachX-AI';      Path = 'F:\ReachX-AI' },
    @{ Name = 'EduConnect';     Path = 'F:\EduConnect' },
    @{ Name = 'OKASINA';        Path = 'C:\Users\ICL  ZAMBIA\Desktop\okasina-fashion-store-vite' },
    @{ Name = 'AOGRL Website';  Path = 'C:\Users\ICL  ZAMBIA\Desktop\AOGRL-Website\aogrl-v3-updated' },
    @{ Name = 'Jules Trading';  Path = 'F:\Jules Trading Platfrom\jules_session_2946937525076603383' }
)

foreach ($p in $projects) {
    $name = $p.Name
    $path = $p.Path

    "" | Out-File -FilePath $reportPath -Append
    "=== $name ==="  | Out-File -FilePath $reportPath -Append
    "Path: $path"    | Out-File -FilePath $reportPath -Append

    if (-not (Test-Path $path)) {
        "Status: MISSING" | Out-File -FilePath $reportPath -Append
        continue
    }

    "Status: OK" | Out-File -FilePath $reportPath -Append

    # Git status & last commit
    if (Test-Path (Join-Path $path '.git')) {
        try {
            "Git status:" | Out-File -FilePath $reportPath -Append
            $gitStatus = git -C $path status --short 2>&1
            if ($gitStatus) {
                $gitStatus | Out-File -FilePath $reportPath -Append
            } else {
                "  clean" | Out-File -FilePath $reportPath -Append
            }

            "Last commit:" | Out-File -FilePath $reportPath -Append
            $gitLast = git -C $path log -1 --oneline 2>&1
            $gitLast | Out-File -FilePath $reportPath -Append
        }
        catch {
            "Git error: $($_.Exception.Message)" | Out-File -FilePath $reportPath -Append
        }
    } else {
        "Git: no .git directory found" | Out-File -FilePath $reportPath -Append
    }

    # Small dir snapshot (top-level items)
    try {
        "Top-level items:" | Out-File -FilePath $reportPath -Append
        Get-ChildItem -LiteralPath $path -Force -ErrorAction SilentlyContinue |
            Select-Object -First 15 Name, Mode, Length |
            Format-Table -AutoSize | Out-String |
            Out-File -FilePath $reportPath -Append
    }
    catch {
        "Dir listing error: $($_.Exception.Message)" | Out-File -FilePath $reportPath -Append
    }
}

""       | Out-File -FilePath $reportPath -Append
"Done."  | Out-File -FilePath $reportPath -Append

Write-Host "Night report written to $reportPath"
