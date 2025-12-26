AOGRL Ops Pack — quick run:
1) powershell -ExecutionPolicy Bypass -File F:\AION-ZERO\py\bin\setup.ps1
2) powershell -ExecutionPolicy Bypass -File F:\AION-ZERO\py\bin\smoke.ps1

Manual:
- CLI ping:  powershell -ExecutionPolicy Bypass -File F:\AION-ZERO\py\bin\launcher.ps1 ping
- cache put: powershell -ExecutionPolicy Bypass -File F:\AION-ZERO\py\bin\launcher.ps1 cache_put foo bar
- cache get: powershell -ExecutionPolicy Bypass -File F:\AION-ZERO\py\bin\launcher.ps1 cache_get foo
