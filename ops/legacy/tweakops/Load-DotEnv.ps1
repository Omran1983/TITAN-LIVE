param(
    [Parameter(Mandatory = $true)]
    [string] $EnvFilePath
)

if (-not (Test-Path -LiteralPath $EnvFilePath)) {
    Write-Warning "Env file not found: $EnvFilePath"
    return
}

Get-Content -LiteralPath $EnvFilePath | ForEach-Object {
    $line = $_.Trim()
    if (-not $line) { return }
    if ($line.StartsWith("#")) { return }

    $idx = $line.IndexOf("=")
    if ($idx -lt 1) { return }

    $key   = $line.Substring(0, $idx).Trim()
    $value = $line.Substring($idx + 1).Trim()

    if ($value.StartsWith('"') -and $value.EndsWith('"')) {
        $value = $value.Trim('"')
    } elseif ($value.StartsWith("'") -and $value.EndsWith("'")) {
        $value = $value.Trim("'")
    }

    if ($key) {
        # This is the safe way to set dynamic env vars
        Set-Item -Path ("Env:{0}" -f $key) -Value $value
    }
}

Write-Host "Loaded env from $EnvFilePath" -ForegroundColor Green
