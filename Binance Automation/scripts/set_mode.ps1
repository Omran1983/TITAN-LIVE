param([ValidateSet("testnet","prod")]$mode="testnet")
if ($mode -eq "testnet") { $env:ENV_FILE = ".env.testnet" }
else { $env:ENV_FILE = ".env.prod" }
Write-Host "[mode]" $mode "ENV_FILE=" $env:ENV_FILE
