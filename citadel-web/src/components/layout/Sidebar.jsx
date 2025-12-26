import React from "react";
import { NavLink } from "react-router-dom";
import { LayoutDashboard, Bot, Terminal, FolderKanban, Landmark } from "lucide-react";

function NavItem({ to, icon: Icon, label }) {
    return (
        <NavLink
            to={to}
            end={to === "/"}
            className={({ isActive }) =>
                [
                    "flex items-center gap-3 px-3 py-2 rounded-lg border",
                    "transition-colors",
                    isActive
                        ? "bg-slate-900 border-sky-500/30 text-slate-100"
                        : "bg-transparent border-transparent text-slate-400 hover:text-slate-200 hover:bg-slate-900/40 hover:border-slate-800",
                ].join(" ")
            }
        >
            <Icon className="w-4 h-4" />
            <span className="text-sm font-semibold tracking-wide">{label}</span>
        </NavLink>
    );
}

export default function Sidebar() {
    return (
        <aside className="w-[260px] shrink-0 border-r border-slate-900/70 bg-slate-950/70 backdrop-blur">
            <div className="p-4 border-b border-slate-900/70">
                <div className="flex items-center gap-3">
                    <div className="w-9 h-9 rounded-xl bg-slate-900 border border-slate-800 flex items-center justify-center">
                        <span className="text-sm font-black text-sky-400">AZ</span>
                    </div>
                    <div className="leading-tight">
                        <div className="text-sm font-extrabold text-slate-100">Titan Command V2</div>
                        <div className="text-[11px] text-slate-500">AION-ZERO · Citadel</div>
                    </div>
                </div>
            </div>

            <nav className="p-3 space-y-1">
                <NavItem to="/" icon={LayoutDashboard} label="Cockpit" />
                <NavItem to="/agents" icon={Bot} label="Agents" />
                <NavItem to="/commands" icon={Terminal} label="Commands" />
                <NavItem to="/projects" icon={FolderKanban} label="Projects" />
                <NavItem to="/finance" icon={Landmark} label="Finance" />
            </nav>

            <div className="p-4 mt-auto border-t border-slate-900/70">
                <div className="text-[11px] text-slate-500">
                    Status: <span className="text-slate-300 font-semibold">Local</span>
                </div>
                <div className="text-[11px] text-slate-500">
                    Guard: <span className="text-emerald-400 font-semibold">Armed</span>
                </div>
            </div>
        </aside>
    );
}
