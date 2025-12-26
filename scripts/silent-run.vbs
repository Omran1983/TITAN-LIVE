' F:\AION-ZERO\scripts\silent-run.vbs
' Run Jarvis startup silently in background

Dim shell
Set shell = CreateObject("WScript.Shell")

' Use Windows PowerShell (5) – works everywhere
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""F:\AION-ZERO\scripts\Jarvis-Startup.ps1""", 0, False
