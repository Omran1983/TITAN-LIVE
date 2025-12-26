param([string]$symbol="BTCUSDT",[double]$tpPct=0.8,[double]$slPct=0.8)
. .\init.ps1 -Mode (Test-Path .\.env.prod) ? "prod" : "testnet" -Symbol $symbol
.\bot.ps1 bracket -symbol $symbol -tpPct $tpPct -slPct $slPct
