import React from "react";
import { AgentGrid } from "../components/AgentGrid/AgentGrid";
import { CommandConsole } from "../components/CommandCenter/Console";
import { Activity, Server, Database, Globe } from "lucide-react";
import { Card } from "../components/ui/Card";

export default function Cockpit() {
    return (
        <div className="space-y-6">
            {/* 1) Page Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-2xl font-semibold text-slate-100">Mission Control</h2>
                    <p className="text-slate-400 text-sm">Overview of Active Systems & Automation Mesh</p>
                </div>

                {/* Visual-only tab strip for now (routing already exists in sidebar) */}
                <div className="flex bg-slate-900/50 p-1 rounded-lg border border-slate-800">
                    <button className="px-3 py-1 text-xs font-bold bg-slate-800 text-slate-100 rounded shadow-sm">
                        COCKPIT
                    </button>
                    <button className="px-3 py-1 text-xs font-bold text-slate-500 hover:text-slate-300">
                        PROJECTS
                    </button>
                    <button className="px-3 py-1 text-xs font-bold text-slate-500 hover:text-slate-300">
                        FINANCE
                    </button>
                </div>
            </div>

            {/* 2) Main Layout */}
            <div className="grid grid-cols-1 lg:grid-cols-[1fr_350px] gap-6">
                <div className="space-y-6">
                    {/* 2.1 Agent Grid */}
                    <AgentGrid />

                    {/* 2.2 Metrics Row (static for Phase 1.1 — will be wired to Health snapshots in Phase 1.2) */}
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                        <Card className="p-4 flex flex-col items-center justify-center gap-1 hover:border-sky-500/50">
                            <Server className="w-5 h-5 text-sky-400" />
                            <span className="text-2xl font-bold text-slate-100">12%</span>
                            <span className="text-[10px] uppercase text-slate-500 font-bold">CPU Load</span>
                        </Card>

                        <Card className="p-4 flex flex-col items-center justify-center gap-1 hover:border-emerald-500/50">
                            <Activity className="w-5 h-5 text-emerald-400" />
                            <span className="text-2xl font-bold text-slate-100">98.2%</span>
                            <span className="text-[10px] uppercase text-slate-500 font-bold">Uptime</span>
                        </Card>

                        <Card className="p-4 flex flex-col items-center justify-center gap-1 hover:border-amber-500/50">
                            <Database className="w-5 h-5 text-amber-400" />
                            <span className="text-2xl font-bold text-slate-100">42ms</span>
                            <span className="text-[10px] uppercase text-slate-500 font-bold">DB Latency</span>
                        </Card>

                        <Card className="p-4 flex flex-col items-center justify-center gap-1 hover:border-purple-500/50">
                            <Globe className="w-5 h-5 text-purple-400" />
                            <span className="text-2xl font-bold text-slate-100">3</span>
                            <span className="text-[10px] uppercase text-slate-500 font-bold">Active Nets</span>
                        </Card>
                    </div>
                </div>

                {/* Right Column */}
                <div className="space-y-4">
                    <CommandConsole />

                    {/* Recent Alerts (placeholder for Phase 1.1) */}
                    <Card className="p-4 space-y-3 bg-slate-900/30">
                        <h3 className="text-xs font-bold text-slate-500 uppercase tracking-widest">
                            Recent Anomalies
                        </h3>

                        <div className="space-y-2">
                            <div className="text-xs flex gap-2">
                                <span className="text-rose-400 font-mono">[13:05]</span>
                                <span className="text-slate-300">Watchdog caught 2 stale tasks.</span>
                            </div>
                            <div className="text-xs flex gap-2">
                                <span className="text-amber-400 font-mono">[12:42]</span>
                                <span className="text-slate-300">API Latency spike &gt; 200ms.</span>
                            </div>
                            <div className="text-xs flex gap-2">
                                <span className="text-emerald-400 font-mono">[11:00]</span>
                                <span className="text-slate-300">Daily Backup verified.</span>
                            </div>
                        </div>
                    </Card>
                </div>
            </div>
        </div>
    );
}
