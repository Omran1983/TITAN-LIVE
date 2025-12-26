@echo off
cd /d "C:\Users\ICL  ZAMBIA\Desktop\Binance Automation"
"C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass -Command ^
  "& { . 'C:\Users\ICL  ZAMBIA\Desktop\Binance Automation\agent.ps1' *>&1 | Tee-Object -FilePath 'C:\Users\ICL  ZAMBIA\Desktop\Binance Automation\journal\agent.console.log' -Append }"
