// src/components/citadel/SideNav.tsx
import React from "react";

export type CitadelTab =
    | "overview" | "brainstem" | "neuron_map" | "reflex" | "logs"
    | "console" | "intents" | "actions" | "audit" | "capabilities"
    | "library"
    | "system" | "agents" | "tools" | "health" | "config";

const Section: React.FC<{ title: string }> = ({ title }) => (
    <div className="text-xs text-white/40 px-2 pb-1 mt-3 first:mt-0">{title}</div>
);

const Item: React.FC<{
    active: boolean;
    label: string;
    onClick: () => void;
}> = ({ active, label, onClick }) => (
    <button
        onClick={onClick}
        className={[
            "w-full text-left px-3 py-2 rounded-lg text-sm border",
            active
                ? "bg-white/10 border-white/15 text-white"
                : "bg-transparent border-transparent text-white/70 hover:bg-white/5 hover:text-white",
        ].join(" ")}
    >
        {label}
    </button>
);

export const SideNav: React.FC<{
    tab: CitadelTab;
    setTab: (t: CitadelTab) => void;
}> = ({ tab, setTab }) => {
    return (
        <div className="w-64 border-r border-white/10 bg-black/20 backdrop-blur p-3 flex flex-col gap-1 overflow-y-auto">
            <Section title="CORE" />
            <Item active={tab === "overview"} label="Overview" onClick={() => setTab("overview")} />
            <Item active={tab === "brainstem"} label="Brainstem" onClick={() => setTab("brainstem")} />
            <Item active={tab === "neuron_map"} label="Neuron Map" onClick={() => setTab("neuron_map")} />
            <Item active={tab === "reflex"} label="Reflex Engine" onClick={() => setTab("reflex")} />
            <Item active={tab === "logs"} label="Logs" onClick={() => setTab("logs")} />

            <Section title="GOVERNANCE (TITAN V2)" />
            <Item active={tab === "console"} label="Console & Agents" onClick={() => setTab("console")} />
            <Item active={tab === "intents"} label="Intents" onClick={() => setTab("intents")} />
            <Item active={tab === "actions"} label="Actions" onClick={() => setTab("actions")} />
            <Item active={tab === "audit"} label="Audit Log" onClick={() => setTab("audit")} />
            <Item active={tab === "capabilities"} label="Capabilities" onClick={() => setTab("capabilities")} />

            <Section title="MARKETPLACE" />
            <Item active={tab === "library"} label="Library" onClick={() => setTab("library")} />

            <Section title="SYSTEM" />
            <Item active={tab === "system"} label="System" onClick={() => setTab("system")} />
            <Item active={tab === "agents"} label="Agents" onClick={() => setTab("agents")} />
            <Item active={tab === "tools"} label="Tools" onClick={() => setTab("tools")} />
            <Item active={tab === "health"} label="Health" onClick={() => setTab("health")} />
            <Item active={tab === "config"} label="Config" onClick={() => setTab("config")} />

            <div className="mt-auto text-xs text-white/35 px-2 pt-3">
                Glass Citadel UI v2.0
            </div>
        </div>
    );
};
