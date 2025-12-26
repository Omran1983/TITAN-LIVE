$envFile = "F:\AION-ZERO\.env"

if (-not (Test-Path $envFile)) {
    Write-Error "Env file not found: $envFile"
    exit 1
}

Get-Content $envFile |
  Where-Object { $_ -and $_ -notmatch '^\s*#' } |
  ForEach-Object {
    $name, $value = $_ -split '=', 2
    $name  = $name.Trim()
    $value = $value.Trim()
    if ($name) {
        ${env:$name} = $value
    }
}

Write-Host "Loaded env vars from $envFile"
