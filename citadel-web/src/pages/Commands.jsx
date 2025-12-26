import React from "react";
import { CommandConsole } from "../components/CommandCenter/Console";
import { Card } from "../components/ui/Card";

export default function Commands() {
    return (
        <div className="space-y-4">
            <div>
                <h2 className="text-2xl font-semibold text-slate-100">Commands</h2>
                <p className="text-slate-400 text-sm">Queue instructions, review command history, and audit outcomes.</p>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-[420px_1fr] gap-6">
                <CommandConsole />

                <Card className="p-4 bg-slate-900/30 space-y-3">
                    <h3 className="text-xs font-bold text-slate-500 uppercase tracking-widest">Command History</h3>
                    <p className="text-sm text-slate-400">
                        Phase 1.2 will wire this to <span className="font-mono text-slate-300">az_commands</span> and/or your local
                        AZ API. For now, this panel is reserved for the table + filters.
                    </p>

                    <div className="text-xs text-slate-500 font-mono border border-slate-800 rounded-lg p-3 bg-slate-950/40">
                        [reserved] status | created_at | project | summary | executed_by
                    </div>
                </Card>
            </div>
        </div>
    );
}
