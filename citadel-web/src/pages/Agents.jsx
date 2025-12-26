import React from "react";
import { AgentGrid } from "../components/AgentGrid/AgentGrid";

export default function Agents() {
    return (
        <div className="space-y-4">
            <div>
                <h2 className="text-2xl font-semibold text-slate-100">Agents</h2>
                <p className="text-slate-400 text-sm">Your army view — status, health, and runtime signals.</p>
            </div>

            <AgentGrid />
        </div>
    );
}
