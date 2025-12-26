function Import-JarvisPolicy {
    param([string]$Path = (Join-Path $PSScriptRoot 'JARVIS-Core-Risk-Policy.txt'))
    if (!(Test-Path -LiteralPath $Path)) { throw "Policy file not found at $Path" }
    $policy = @{}
    Get-Content -LiteralPath $Path -Encoding UTF8 | ForEach-Object {
        if ($_ -match '^\s*([^#=]+?)\s*=\s*(.*)$') {
            $name = $Matches[1].Trim()
            $val  = $Matches[2].Trim()
            $policy[$name] = $val
        }
    }
    return $policy
}
