import React from "react";
import { Card } from "../components/ui/Card";

export default function Finance() {
    return (
        <div className="space-y-4">
            <div>
                <h2 className="text-2xl font-semibold text-slate-100">Finance</h2>
                <p className="text-slate-400 text-sm">
                    Money Math cockpit. Phase 1.2 will connect to your Supabase views (KPIs + cashflow).
                </p>
            </div>

            {/* KPI Row (empty state) */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <Card className="p-4 bg-slate-900/30 space-y-2">
                    <div className="text-xs font-bold text-slate-500 uppercase tracking-widest">Today Net</div>
                    <div className="text-2xl font-black text-slate-200">—</div>
                    <div className="text-xs text-slate-500">Awaiting: az_finance_kpi_today</div>
                </Card>

                <Card className="p-4 bg-slate-900/30 space-y-2">
                    <div className="text-xs font-bold text-slate-500 uppercase tracking-widest">Month Net</div>
                    <div className="text-2xl font-black text-slate-200">—</div>
                    <div className="text-xs text-slate-500">Awaiting: az_finance_kpi_month</div>
                </Card>

                <Card className="p-4 bg-slate-900/30 space-y-2">
                    <div className="text-xs font-bold text-slate-500 uppercase tracking-widest">Cashflow (30d)</div>
                    <div className="text-2xl font-black text-slate-200">—</div>
                    <div className="text-xs text-slate-500">Awaiting: az_finance_cashflow_30d</div>
                </Card>
            </div>

            {/* Chart Reserved */}
            <Card className="p-4 bg-slate-900/30 space-y-3">
                <div className="text-xs font-bold text-slate-500 uppercase tracking-widest">Cashflow Chart</div>
                <p className="text-sm text-slate-400">
                    Reserved for Recharts. We’ll render Income/Expense/Net once the view exists.
                </p>

                <div className="h-56 rounded-lg border border-slate-800 bg-slate-950/40 flex items-center justify-center">
                    <span className="text-xs text-slate-600 font-mono">[Recharts area reserved]</span>
                </div>
            </Card>
        </div>
    );
}
