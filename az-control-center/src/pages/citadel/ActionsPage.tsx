// src/pages/citadel/ActionsPage.tsx
import React, { useState } from "react";
import { apiPost } from "../../lib/api";
import type { ActionRunRequest, ActionRunResponse } from "../../lib/types";
import { Panel } from "../../components/citadel/Panel";
import { JsonBox } from "../../components/citadel/JsonBox";

export const ActionsPage: React.FC<{ token: string }> = ({ token }) => {
    const [actionKey, setActionKey] = useState("titan:health");
    const [intentId, setIntentId] = useState<string>("");
    const [out, setOut] = useState<any>(null);
    const [err, setErr] = useState<string | null>(null);
    const [busy, setBusy] = useState(false);

    const run = async () => {
        setBusy(true);
        setErr(null);
        setOut(null);
        try {
            const payload: ActionRunRequest = {
                action_key: actionKey,
                intent_id: intentId.trim() ? intentId.trim() : null,
            };
            const res = await apiPost<ActionRunResponse>("/api/actions/run", payload, { token });
            setOut(res);
        } catch (e: any) {
            setErr(e.message || String(e));
        } finally {
            setBusy(false);
        }
    };

    return (
        <div className="space-y-4">
            <Panel
                title="Run Action"
                subtitle="Governed action executor. Risk >= L2 requires approved intent."
            >
                <div className="grid md:grid-cols-2 gap-3">
                    <div>
                        <label className="text-xs text-white/50">Action Key</label>
                        <input
                            value={actionKey}
                            onChange={(e) => setActionKey(e.target.value)}
                            className="w-full mt-1 px-3 py-2 rounded-lg bg-white/5 border border-white/10 outline-none text-white/85"
                            placeholder="titan:health"
                        />
                    </div>
                    <div>
                        <label className="text-xs text-white/50">Intent ID (optional)</label>
                        <input
                            value={intentId}
                            onChange={(e) => setIntentId(e.target.value)}
                            className="w-full mt-1 px-3 py-2 rounded-lg bg-white/5 border border-white/10 outline-none text-white/85"
                            placeholder="uuid (required for L2+)"
                        />
                    </div>
                </div>

                <div className="flex gap-2 mt-4">
                    <button
                        onClick={run}
                        disabled={busy}
                        className="px-4 py-2 rounded-lg bg-white/10 border border-white/10 text-white/85 hover:bg-white/15"
                    >
                        {busy ? "Running..." : "Execute"}
                    </button>
                </div>

                {err ? <div className="text-red-300 text-sm mt-3">{err}</div> : null}
                {out ? (
                    <div className="mt-3">
                        <div className="text-xs text-white/50 mb-1">Result</div>
                        <JsonBox value={out} />
                    </div>
                ) : null}
            </Panel>
        </div>
    );
};
