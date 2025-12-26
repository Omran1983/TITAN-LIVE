// src/pages/CitadelPage.tsx
import React, { useEffect, useMemo, useState } from "react";
import { TopBar } from "../components/citadel/TopBar";
import { SideNav, CitadelTab } from "../components/citadel/SideNav";

import { OverviewPage } from "./OverviewPage";
import { BrainstemPage } from "./BrainstemPage";
import { NeuronMapPage } from "./NeuronMapPage";
import { ReflexesPage } from "./ReflexesPage";
import { LogsPage } from "./LogsPage";
import { LibraryPage } from "./LibraryPage";
import { SystemPage } from "./SystemPage";
import { AgentsPage } from "./AgentsPage";
import { ToolsPage } from "./ToolsPage";
import { ConfigPage } from "./ConfigPage";
import { HealthPage as LegacyHealthPage } from "./HealthPage"; // Renaming legacy health to avoid conflict

import { ConsoleAgents } from "./citadel/ConsoleAgents";
import { IntentsPage } from "./citadel/IntentsPage";
import { ActionsPage } from "./citadel/ActionsPage";
import { AuditPage } from "./citadel/AuditPage";
import { CapabilitiesPage } from "./citadel/CapabilitiesPage";
import { HealthPage as CitadelHealthPage } from "./citadel/HealthPage";

export const CitadelPage: React.FC = () => {
    const [tab, setTab] = useState<CitadelTab>("console");
    const [token, setToken] = useState<string>("OPERATOR");

    return (
        <div className="min-h-screen bg-[#07090f] text-white flex flex-col overflow-hidden">
            <TopBar token={token} setToken={setToken} />

            <div className="flex flex-1 overflow-hidden">
                <SideNav tab={tab} setTab={setTab} />

                <div className="flex-1 p-4 overflow-auto">
                    {/* CORE */}
                    {tab === "overview" && <OverviewPage />}
                    {tab === "brainstem" && <BrainstemPage />}
                    {tab === "neuron_map" && <NeuronMapPage />}
                    {tab === "reflex" && <ReflexesPage />}
                    {tab === "logs" && <LogsPage />}

                    {/* GOVERNANCE */}
                    {tab === "console" && <ConsoleAgents token={token} />}
                    {tab === "intents" && <IntentsPage token={token} />}
                    {tab === "actions" && <ActionsPage token={token} />}
                    {tab === "audit" && <AuditPage token={token} />}
                    {tab === "capabilities" && <CapabilitiesPage token={token} />}

                    {/* MARKETPLACE */}
                    {tab === "library" && <LibraryPage />}

                    {/* SYSTEM */}
                    {tab === "system" && <SystemPage />}
                    {tab === "agents" && <AgentsPage />}
                    {tab === "tools" && <ToolsPage />}
                    {tab === "health" && <CitadelHealthPage token={token} />}
                    {tab === "config" && <ConfigPage />}
                </div>
            </div>
        </div>
    );
};
