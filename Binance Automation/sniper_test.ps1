# sniper_test.ps1 - tiny sanity test for exchangeInfo URI building
$ErrorActionPreference = "Stop"

$Base = "https://api.binance.com"
$Pairs = "BTCUSDT ETHUSDT,  ethusdt "   # messy input on purpose

# Normalize and split into an array of clean symbols
$pairList = ($Pairs -split '[,\s]+' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' } | ForEach-Object { $_.ToUpperInvariant() })

Write-Host "Symbols to test: $($pairList -join ', ')"

foreach ($symbol in $pairList) {
    if ($symbol -notmatch '^[A-Z0-9\-\._]{1,20}$') {
        Write-Warning "Skipping invalid symbol format: '$symbol'"
        continue
    }

    $baseTrimmed = $Base.TrimEnd('/')
    $path = "/api/v3/exchangeInfo"
    $query = "symbol=$symbol"

    # SAFE URI (concatenation avoids $path? parsing)
    $uri = $baseTrimmed + $path + '?' + $query

    Write-Host "Calling (no keys shown): $uri"
    try {
        $resp = Invoke-RestMethod -Uri $uri -Method GET -ErrorAction Stop
        if ($resp -and $resp.symbols) {
            Write-Host "exchangeInfo OK for $symbol"
        } else {
            Write-Warning "exchangeInfo returned unexpected payload for $symbol"
        }
    } catch {
        Write-Error "exchangeInfo failed for $symbol : $($_.Exception.Message)"
    }

    Start-Sleep -Milliseconds 200
}
