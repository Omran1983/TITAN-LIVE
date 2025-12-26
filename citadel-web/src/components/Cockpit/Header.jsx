import React from 'react';
import { ShieldAlert, Activity } from 'lucide-react';

export function Header() {
    return (
        <header className="border-b border-slate-800 bg-slate-950/80 backdrop-blur sticky top-0 z-50">
            <div className="max-w-7xl mx-auto px-4 h-16 flex items-center justify-between">

                {/* Branding */}
                <div>
                    <h1 className="text-xl font-bold tracking-tight text-slate-100">
                        Titan Command <span className="text-sky-400">· AION-ZERO</span>
                    </h1>
                    <div className="flex items-center gap-2 text-xs text-slate-500 font-mono mt-0.5">
                        <span>REACT-ENGINE-V2</span>
                        <span className="text-slate-700">|</span>
                        <span>OMRAN-AHMAD-AUTH</span>
                    </div>
                </div>

                {/* Status / Controls */}
                <div className="flex items-center gap-4">
                    <div className="hidden md:flex flex-col items-end text-xs">
                        <span className="text-slate-500">SYSTEM STATUS</span>
                        <span className="flex items-center gap-1.5 text-emerald-400 font-bold animate-pulse">
                            <Activity className="w-3 h-3" />
                            ONLINE
                        </span>
                    </div>

                    <button className="flex items-center gap-2 px-3 py-1.5 rounded bg-rose-500/10 border border-rose-500/50 text-rose-400 hover:bg-rose-500/20 hover:text-rose-100 transition-colors text-xs font-bold uppercase tracking-wider">
                        <ShieldAlert className="w-3 h-3" />
                        Panic Stop
                    </button>
                </div>
            </div>
        </header>
    );
}
