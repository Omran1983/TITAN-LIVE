$ErrorActionPreference = "Stop"

$okasinaRoot = "C:\Users\ICL  ZAMBIA\Desktop\okasina-fashion-store-vite"

if (-not (Test-Path $okasinaRoot)) {
    Write-Host "OKASINA root not found: $okasinaRoot" -ForegroundColor Red
    exit 1
}

# 1) Ensure Supabase client file exists
$srcDir       = Join-Path $okasinaRoot "src"
$supabasePath = Join-Path $srcDir "supabase.js"

New-Item -ItemType Directory -Path $srcDir -Force | Out-Null

$supabaseJs = @"
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://iutpfbtpizshqeevxmke.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1dHBmYnRwaXpzaHFlZXZ4bWtlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc1NTEwMDksImV4cCI6MjA2MzEyNzAwOX0.gQRWLD-cYDkXnNBlXsmy0s1FBjc3NJHTl3UJuhzIOOI';

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase URL or anon key in supabase.js');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
"@

Set-Content -Path $supabasePath -Value $supabaseJs -Encoding UTF8

# 2) Rewrite AdminOrdersPage.jsx to use real Supabase orders
$componentDir        = Join-Path $okasinaRoot "src\components"
$adminOrdersPagePath = Join-Path $componentDir "AdminOrdersPage.jsx"

New-Item -ItemType Directory -Path $componentDir -Force | Out-Null

$adminOrdersJsx = @"
import React, { useEffect, useState } from 'react';
import { supabase } from '../supabase';
import OrdersDashboard from './OrdersDashboard';

export default function AdminOrdersPage() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState('');

  useEffect(() => {
    async function loadOrders() {
      setLoading(true);
      setErrorMsg('');
      try {
        const { data, error } = await supabase
          .from('orders')
          .select('*')
          .order('created_at', { ascending: false })
          .limit(200);

        if (error) {
          console.error('Supabase orders error:', error);
          setErrorMsg(error.message || 'Failed to load orders.');
          setOrders([]);
        } else {
          setOrders(data || []);
        }
      } catch (err) {
        console.error('Unexpected error loading orders:', err);
        setErrorMsg('Unexpected error loading orders.');
        setOrders([]);
      } finally {
        setLoading(false);
      }
    }

    loadOrders();
  }, []);

  if (loading) {
    return (
      <div className="w-full h-full flex items-center justify-center text-slate-300">
        Loading orders from Supabase...
      </div>
    );
  }

  if (errorMsg) {
    return (
      <div className="w-full h-full flex flex-col items-center justify-center gap-3 p-4 bg-slate-950 text-slate-100">
        <div className="px-4 py-2 rounded bg-red-900/40 border border-red-500/70 text-sm">
          Error loading orders: {errorMsg}
        </div>
        <button
          className="px-3 py-1.5 text-xs rounded bg-slate-800 border border-slate-600 hover:bg-slate-700"
          onClick={() => window.location.reload()}
        >
          Retry
        </button>
      </div>
    );
  }

  return <OrdersDashboard orders={orders} />;
}
"@

Set-Content -Path $adminOrdersPagePath -Value $adminOrdersJsx -Encoding UTF8

# 3) Log OKASINA Supabase build
$logDir       = "F:\AION-ZERO\logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$okaJournal   = Join-Path $logDir "okasina-build-journal.md"

$entry = @"
## OKASINA Build (Supabase Orders) $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Files updated:
- $supabasePath
- $adminOrdersPagePath

Notes:
- AdminOrdersPage now pulls from Supabase 'orders' table (last 200, newest first).
"@

Add-Content -Path $okaJournal -Value $entry

Write-Host "OKASINA Supabase orders build completed." -ForegroundColor Green
Write-Host "  Supabase client: $supabasePath" -ForegroundColor Green
Write-Host "  AdminOrdersPage: $adminOrdersPagePath" -ForegroundColor Green
