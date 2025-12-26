import React from "react";
import { Card } from "../components/ui/Card";

function ProjectCard({ name, status, note }) {
    const statusClass =
        status === "ok"
            ? "text-emerald-400"
            : status === "warn"
                ? "text-amber-400"
                : status === "down"
                    ? "text-rose-400"
                    : "text-slate-400";

    return (
        <Card className="p-4 bg-slate-900/30 space-y-2">
            <div className="flex items-center justify-between">
                <div className="text-lg font-bold text-slate-100">{name}</div>
                <div className={`text-xs font-black uppercase tracking-widest ${statusClass}`}>
                    {status.toUpperCase()}
                </div>
            </div>
            <p className="text-sm text-slate-400">{note}</p>
        </Card>
    );
}

export default function Projects() {
    return (
        <div className="space-y-4">
            <div>
                <h2 className="text-2xl font-semibold text-slate-100">Projects</h2>
                <p className="text-slate-400 text-sm">Operational view across OKASINA, ReachX, EduConnect, DS, and AION-ZERO.</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <ProjectCard name="AION-ZERO" status="ok" note="Core mesh and command plane running." />
                <ProjectCard name="OKASINA" status="warn" note="E-commerce system — pending stability + automation hardening." />
                <ProjectCard name="ReachX" status="ok" note="Recruitment/workforce pipeline — UI/flows in progress." />
                <ProjectCard name="AOGRL-DS" status="down" note="Parked until automation factory is fully hands-off." />
            </div>
        </div>
    );
}
