$ErrorActionPreference = "Stop"

$okaRoot = "C:\Users\ICL  ZAMBIA\Desktop\okasina-fashion-store-vite"
$appPath = Join-Path $okaRoot "src\App.jsx"
$logDir  = "F:\AION-ZERO\logs"

if (-not (Test-Path $appPath)) {
    Write-Host "App.jsx not found at $appPath" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Path $logDir -Force | Out-Null

$timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = "$appPath.bak-$timestamp"

Copy-Item $appPath $backupPath -Force
Write-Host "Backup of App.jsx created: $backupPath" -ForegroundColor Yellow

$appJsx = @"
import React from "react";
import AdminOrdersPage from "./components/AdminOrdersPage";

function App() {
  return (
    <div className="min-h-screen bg-slate-950 text-slate-100">
      <div className="max-w-6xl mx-auto py-6 px-4">
        <header className="mb-4 border-b border-slate-800 pb-3">
          <h1 className="text-2xl font-semibold tracking-tight">
            OKASINA Admin · Orders
          </h1>
          <p className="text-sm text-slate-400">
            Live Supabase orders view with filters, totals, and CSV export.
          </p>
        </header>
        <AdminOrdersPage />
      </div>
    </div>
  );
}

export default App;
"@

Set-Content -Path $appPath -Value $appJsx -Encoding UTF8

$okaJournal = Join-Path $logDir "okasina-build-journal.md"
$entry = @"
## OKASINA Build (Wire AdminOrders as App) $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Files updated:
- $appPath

Backup:
- $backupPath

Notes:
- App.jsx now renders AdminOrdersPage as the main view for the SPA.
"@
Add-Content -Path $okaJournal -Value $entry

Write-Host "OKASINA App.jsx now wired to AdminOrdersPage." -ForegroundColor Green
