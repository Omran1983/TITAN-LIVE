param(
    [string]$Port = "8005"
)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here

Set-Location $root

python -m uvicorn api.main:app --host 127.0.0.1 --port $Port --reload
