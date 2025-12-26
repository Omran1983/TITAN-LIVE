# TITAN ⇄ ChatGPT Bridge (Laptop-First)

## Push/Pull
- Pull task from clipboard into TITAN inbox:
  powershell -ExecutionPolicy Bypass -File .\bridge_pull.ps1

- OR pull from a file:
  powershell -ExecutionPolicy Bypass -File .\bridge_pull.ps1 -FromFile "C:\path\task.json"

- Push latest result to clipboard:
  powershell -ExecutionPolicy Bypass -File .\bridge_push.ps1

- Quick status:
  powershell -ExecutionPolicy Bypass -File .\bridge_status.ps1

## Loop
1) Paste task JSON from ChatGPT → bridge_pull.ps1
2) Runner executes
3) bridge_push.ps1
4) Paste result JSON to ChatGPT
