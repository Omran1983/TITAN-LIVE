$ErrorActionPreference = "Stop"

$okasinaRoot = "C:\Users\ICL  ZAMBIA\Desktop\okasina-fashion-store-vite"

if (-not (Test-Path $okasinaRoot)) {
    Write-Host "OKASINA root not found: $okasinaRoot" -ForegroundColor Red
    exit 1
}

$componentDir = Join-Path $okasinaRoot "src\components"
New-Item -ItemType Directory -Path $componentDir -Force | Out-Null

$filesCreated = @()

# -----------------------------
# OrdersDashboard.jsx
# -----------------------------
$ordersDashboardPath = Join-Path $componentDir "OrdersDashboard.jsx"

$ordersDashboardJsx = @"
import React, { useMemo, useState } from 'react';

const STATUS_OPTIONS = ['all', 'pending', 'processing', 'shipped', 'delivered', 'cancelled'];

function formatDate(value) {
  if (!value) return '';
  try {
    const d = new Date(value);
    return d.toLocaleString();
  } catch {
    return String(value);
  }
}

export default function OrdersDashboard({ orders = [] }) {
  const [statusFilter, setStatusFilter] = useState('all');
  const [search, setSearch] = useState('');

  const filteredOrders = useMemo(() => {
    const s = search.trim().toLowerCase();
    return (orders || []).filter((order) => {
      const statusOk =
        statusFilter === 'all' ||
        String(order.status || '').toLowerCase() === statusFilter;

      const text =
        String(order.id ?? '') +
        ' ' +
        String(order.customerName ?? '') +
        ' ' +
        String(order.customerPhone ?? '') +
        ' ' +
        String(order.customerEmail ?? '');

      const searchOk = s === '' || text.toLowerCase().includes(s);
      return statusOk && searchOk;
    });
  }, [orders, statusFilter, search]);

  return (
    <div className="w-full h-full flex flex-col gap-4 p-4 bg-slate-950/90 text-slate-100">
      <header className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
        <div>
          <h1 className="text-xl md:text-2xl font-semibold tracking-tight">
            Orders Dashboard
          </h1>
          <p className="text-sm text-slate-400">
            Review, filter and search customer orders. Next step: connect this
            to Supabase orders table.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <div className="flex flex-col text-xs">
            <span className="text-slate-400">Total Orders</span>
            <span className="text-lg font-bold">{orders?.length ?? 0}</span>
          </div>
          <div className="flex flex-col text-xs">
            <span className="text-slate-400">Showing</span>
            <span className="text-lg font-bold">
              {filteredOrders?.length ?? 0}
            </span>
          </div>
        </div>
      </header>

      <section className="flex flex-col md:flex-row gap-3">
        <div className="flex items-center gap-2">
          <label className="text-xs text-slate-400">Status</label>
          <select
            className="bg-slate-900 border border-slate-700 text-xs px-2 py-1 rounded"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            {STATUS_OPTIONS.map((opt) => (
              <option key={opt} value={opt}>
                {opt === 'all'
                  ? 'All'
                  : opt.charAt(0).toUpperCase() + opt.slice(1)}
              </option>
            ))}
          </select>
        </div>

        <div className="flex-1">
          <input
            className="w-full bg-slate-900 border border-slate-700 rounded px-3 py-1.5 text-xs"
            placeholder="Search by order ID, customer name, phone or email"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
      </section>

      <section className="flex-1 overflow-auto border border-slate-800 rounded-lg bg-slate-900/60">
        <table className="min-w-full text-xs">
          <thead className="bg-slate-900/80 sticky top-0 z-10">
            <tr className="border-b border-slate-800">
              <th className="px-3 py-2 text-left font-medium text-slate-300">
                Order ID
              </th>
              <th className="px-3 py-2 text-left font-medium text-slate-300">
                Customer
              </th>
              <th className="px-3 py-2 text-left font-medium text-slate-300">
                Status
              </th>
              <th className="px-3 py-2 text-right font-medium text-slate-300">
                Total (Rs)
              </th>
              <th className="px-3 py-2 text-left font-medium text-slate-300">
                Created
              </th>
            </tr>
          </thead>
          <tbody>
            {filteredOrders.length === 0 ? (
              <tr>
                <td
                  colSpan={5}
                  className="px-3 py-6 text-center text-slate-500"
                >
                  No orders match the current filters.
                </td>
              </tr>
            ) : (
              filteredOrders.map((order) => (
                <tr
                  key={order.id}
                  className="border-t border-slate-800 hover:bg-slate-800/60 transition-colors"
                >
                  <td className="px-3 py-2 font-mono text-[11px]">
                    {order.id ?? '-'}
                  </td>
                  <td className="px-3 py-2">
                    <div className="flex flex-col">
                      <span className="font-medium">
                        {order.customerName ?? '-'}
                      </span>
                      <span className="text-[11px] text-slate-400">
                        {order.customerPhone ?? order.customerEmail ?? ''}
                      </span>
                    </div>
                  </td>
                  <td className="px-3 py-2">
                    <span className="inline-flex items-center rounded-full border border-slate-700 px-2 py-[2px] text-[11px]">
                      {order.status ?? 'unknown'}
                    </span>
                  </td>
                  <td className="px-3 py-2 text-right">
                    {order.totalAmount ?? order.total ?? 0}
                  </td>
                  <td className="px-3 py-2 text-[11px] text-slate-400">
                    {formatDate(order.created_at ?? order.createdAt)}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </section>
    </div>
  );
}
"@

Set-Content -Path $ordersDashboardPath -Value $ordersDashboardJsx -Encoding UTF8
$filesCreated += $ordersDashboardPath

# -----------------------------
# AdminOrdersPage.jsx
# -----------------------------
$adminOrdersPath = Join-Path $componentDir "AdminOrdersPage.jsx"

$adminJsx = @"
import React, { useEffect, useState } from 'react';
import OrdersDashboard from './OrdersDashboard';

export default function AdminOrdersPage() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);

  // TODO: replace this mock with Supabase query
  useEffect(() => {
    const mock = [
      {
        id: 'OK-1001',
        customerName: 'Test Customer',
        customerPhone: '2300000000',
        status: 'pending',
        totalAmount: 1500,
        created_at: new Date().toISOString(),
      },
    ];
    setOrders(mock);
    setLoading(false);
  }, []);

  if (loading) {
    return (
      <div className="w-full h-full flex items-center justify-center text-slate-300">
        Loading orders...
      </div>
    );
  }

  return <OrdersDashboard orders={orders} />;
}
"@

Set-Content -Path $adminOrdersPath -Value $adminJsx -Encoding UTF8
$filesCreated += $adminOrdersPath

# -----------------------------
# Log OKASINA build
# -----------------------------
$logDir = "F:\AION-ZERO\logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$journalPath = Join-Path $logDir "okasina-build-journal.md"

$entry = @"
## OKASINA Build $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Files updated:
- $ordersDashboardPath
- $adminOrdersPath

"@

Add-Content -Path $journalPath -Value $entry

Write-Host "OKASINA build completed. Files touched:" -ForegroundColor Green
$filesCreated | ForEach-Object { Write-Host "  $_" -ForegroundColor Green }
