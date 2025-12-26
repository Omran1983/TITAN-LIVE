param(
    [Parameter(Mandatory = $true)]
    [string]$EnvFilePath
)

if (-not (Test-Path $EnvFilePath)) {
    throw "Env file not found at $EnvFilePath"
}

Get-Content $EnvFilePath | ForEach-Object {
    $line = $_.Trim()
    if (-not $line) { return }
    if ($line.StartsWith("#")) { return }

    $parts = $line -split "=", 2
    if ($parts.Count -ne 2) { return }

    $name  = $parts[0].Trim()
    $value = $parts[1].Trim()

    [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
}

Write-Host "Loaded env from $EnvFilePath"
