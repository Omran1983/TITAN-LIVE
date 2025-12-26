// src/pages/citadel/AuditPage.tsx
import React, { useState } from "react";
import { Panel } from "../../components/citadel/Panel";
import { JsonBox } from "../../components/citadel/JsonBox";
import { apiGet } from "../../lib/api";
import type { AuditLogItem } from "../../lib/types";

type AuditResponse = { ok: boolean; items: AuditLogItem[] };

export const AuditPage: React.FC<{ token: string }> = ({ token }) => {
    const [items, setItems] = useState<AuditLogItem[] | null>(null);
    const [err, setErr] = useState<string | null>(null);
    const [loading, setLoading] = useState(false);

    const load = async () => {
        setLoading(true);
        setErr(null);
        try {
            // NOTE: This endpoint is not in the Flask bundle yet.
            // If you add /api/audit?limit=200, this page will light up instantly.
            const r = await apiGet<AuditResponse>("/api/audit?limit=200", { token });
            setItems(r.items);
        } catch (e: any) {
            setErr(e.message || String(e));
            setItems(null);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="space-y-4">
            <Panel
                title="Audit Log"
                subtitle="Every governed action & agent run (intent-linked)."
                right={
                    <button
                        onClick={load}
                        disabled={loading}
                        className="px-3 py-2 rounded-lg bg-white/10 border border-white/10 text-white/85 hover:bg-white/15"
                    >
                        {loading ? "Loading..." : "Load"}
                    </button>
                }
            >
                {err ? (
                    <div className="text-yellow-200 text-sm">
                        Audit endpoint not wired yet (expected). Error:
                        <div className="text-red-300 mt-1">{err}</div>
                        <div className="text-white/60 mt-2">
                            Fix: add <span className="text-white">GET /api/audit?limit=...</span> in TITAN server (I can paste the full Flask code next).
                        </div>
                    </div>
                ) : null}

                {items ? (
                    <div className="grid lg:grid-cols-2 gap-3 mt-3">
                        {items.map((x) => (
                            <div key={x.id} className="rounded-2xl border border-white/10 bg-black/35 p-3">
                                <div className="text-sm text-white font-semibold">
                                    {x.action_key} <span className={x.ok ? "text-emerald-300" : "text-red-300"}>{x.ok ? "OK" : "FAIL"}</span>
                                </div>
                                <div className="text-xs text-white/50 mt-1">
                                    {new Date(x.created_at).toLocaleString()} · actor={x.actor}:{x.actor_id} · intent={x.intent_id ?? "-"}
                                </div>
                                <div className="mt-3">
                                    <JsonBox value={{ request: x.request, result: x.result, error: x.error }} />
                                </div>
                            </div>
                        ))}
                    </div>
                ) : null}
            </Panel>
        </div>
    );
};
