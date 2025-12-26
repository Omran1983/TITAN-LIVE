// src/pages/citadel/IntentsPage.tsx
import React, { useState } from "react";
import { apiPost } from "../../lib/api";
import type {
    IntentCreateRequest,
    IntentCreateResponse,
    IntentApproveResponse,
} from "../../lib/types";
import { Panel } from "../../components/citadel/Panel";
import { JsonBox } from "../../components/citadel/JsonBox";

export const IntentsPage: React.FC<{ token: string }> = ({ token }) => {
    const [proposedAction, setProposedAction] = useState("titan:website_review");
    const [risk, setRisk] = useState<"L0" | "L1" | "L2" | "L3" | "L4">("L1");
    const [confidence, setConfidence] = useState(0.75);
    const [explanation, setExplanation] = useState("Need to run a governed operation.");
    const [created, setCreated] = useState<any>(null);
    const [approveId, setApproveId] = useState("");
    const [approved, setApproved] = useState<any>(null);
    const [err, setErr] = useState<string | null>(null);
    const [busy, setBusy] = useState(false);

    const createIntent = async () => {
        setBusy(true);
        setErr(null);
        setCreated(null);
        try {
            const payload: IntentCreateRequest = {
                agent_name: "az-ui",
                ui_intent: "action_proposal",
                proposed_action: proposedAction,
                confidence,
                risk_level: risk,
                explanation,
                decision_metadata: { source: "Citadel UI" },
            };
            const res = await apiPost<IntentCreateResponse>("/api/governance/intent", payload, { token });
            setCreated(res);
            setApproveId(res.intent_id);
        } catch (e: any) {
            setErr(e.message || String(e));
        } finally {
            setBusy(false);
        }
    };

    const approveIntent = async () => {
        if (!approveId.trim()) return;
        setBusy(true);
        setErr(null);
        setApproved(null);
        try {
            const res = await apiPost<IntentApproveResponse>(
                `/api/governance/intent/${approveId}/approve`,
                {},
                { token }
            );
            setApproved(res);
        } catch (e: any) {
            setErr(e.message || String(e));
        } finally {
            setBusy(false);
        }
    };

    return (
        <div className="space-y-4">
            <Panel title="Create Intent" subtitle="Intents are your traceability + governance ledger.">
                <div className="grid md:grid-cols-2 gap-3">
                    <div>
                        <label className="text-xs text-white/50">Proposed Action</label>
                        <input
                            title="Proposed Action"
                            value={proposedAction}
                            onChange={(e) => setProposedAction(e.target.value)}
                            className="w-full mt-1 px-3 py-2 rounded-lg bg-white/5 border border-white/10 outline-none text-white/85"
                            placeholder="e.g. titan:restart_n8n"
                        />
                    </div>
                    <div>
                        <label className="text-xs text-white/50">Risk Level</label>
                        <select
                            title="Risk Level"
                            value={risk}
                            onChange={(e) => setRisk(e.target.value as any)}
                            className="w-full mt-1 px-3 py-2 rounded-lg bg-white/5 border border-white/10 outline-none text-white/85"
                        >
                            <option value="L0">L0</option>
                            <option value="L1">L1</option>
                            <option value="L2">L2</option>
                            <option value="L3">L3</option>
                            <option value="L4">L4</option>
                        </select>
                    </div>

                    <div>
                        <label className="text-xs text-white/50">Confidence</label>
                        <input
                            title="Confidence Score"
                            type="number"
                            step="0.05"
                            min="0"
                            max="1"
                            value={confidence}
                            onChange={(e) => setConfidence(parseFloat(e.target.value))}
                            className="w-full mt-1 px-3 py-2 rounded-lg bg-white/5 border border-white/10 outline-none text-white/85"
                        />
                    </div>

                    <div className="md:col-span-2">
                        <label className="text-xs text-white/50">Explanation</label>
                        <textarea
                            title="Explanation"
                            value={explanation}
                            onChange={(e) => setExplanation(e.target.value)}
                            className="w-full mt-1 px-3 py-2 rounded-lg bg-white/5 border border-white/10 outline-none text-white/85 min-h-[90px]"
                        />
                    </div>
                </div>

                <div className="flex gap-2 mt-4">
                    <button
                        onClick={createIntent}
                        disabled={busy}
                        className="px-4 py-2 rounded-lg bg-white/10 border border-white/10 text-white/85 hover:bg-white/15"
                    >
                        {busy ? "Working..." : "Create Intent"}
                    </button>
                </div>

                {err ? <div className="text-red-300 text-sm mt-3">{err}</div> : null}
                {created ? (
                    <div className="mt-3">
                        <div className="text-xs text-white/50 mb-1">Created</div>
                        <JsonBox value={created} />
                    </div>
                ) : null}
            </Panel>

            <Panel title="Approve Intent" subtitle="Requires ADMIN/L3+ according to server rules.">
                <div className="flex flex-col md:flex-row gap-2">
                    <input
                        value={approveId}
                        onChange={(e) => setApproveId(e.target.value)}
                        className="flex-1 px-3 py-2 rounded-lg bg-white/5 border border-white/10 outline-none text-white/85"
                        placeholder="intent_id"
                    />
                    <button
                        onClick={approveIntent}
                        disabled={busy}
                        className="px-4 py-2 rounded-lg bg-white/10 border border-white/10 text-white/85 hover:bg-white/15"
                    >
                        {busy ? "Working..." : "Approve"}
                    </button>
                </div>

                {approved ? (
                    <div className="mt-3">
                        <div className="text-xs text-white/50 mb-1">Approved</div>
                        <JsonBox value={approved} />
                    </div>
                ) : null}
            </Panel>
        </div>
    );
};
