// src/pages/citadel/CapabilitiesPage.tsx
import React, { useEffect, useMemo, useState } from "react";
import { apiGet } from "../../lib/api";
import type { CapabilitiesResponse } from "../../lib/types";
import { Panel } from "../../components/citadel/Panel";
import { JsonBox } from "../../components/citadel/JsonBox";

export const CapabilitiesPage: React.FC<{ token: string }> = ({ token }) => {
    const [data, setData] = useState<CapabilitiesResponse | null>(null);
    const [err, setErr] = useState<string | null>(null);
    const [loading, setLoading] = useState(false);
    const [q, setQ] = useState("");

    const load = async () => {
        setLoading(true);
        setErr(null);
        try {
            const r = await apiGet<CapabilitiesResponse>("/api/capabilities", { token });
            setData(r);
        } catch (e: any) {
            setErr(e.message || String(e));
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        load();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    const items = useMemo(() => {
        const list = data?.items ?? [];
        const s = q.trim().toLowerCase();
        if (!s) return list;
        return list.filter((x) => {
            const blob = `${x.kind} ${x.name} ${x.category ?? ""} ${JSON.stringify(x.capability_meta ?? {})}`.toLowerCase();
            return blob.includes(s);
        });
    }, [data, q]);

    return (
        <div className="space-y-4">
            <Panel
                title="Capabilities"
                subtitle="What the system has learned/registered."
                right={
                    <button
                        onClick={load}
                        disabled={loading}
                        className="px-3 py-2 rounded-lg bg-white/10 border border-white/10 text-white/85 hover:bg-white/15"
                    >
                        {loading ? "Refreshing..." : "Refresh"}
                    </button>
                }
            >
                <div className="flex gap-2 mb-3">
                    <input
                        value={q}
                        onChange={(e) => setQ(e.target.value)}
                        className="flex-1 px-3 py-2 rounded-lg bg-white/5 border border-white/10 outline-none text-white/85"
                        placeholder="Search capabilities..."
                    />
                </div>

                {err ? <div className="text-red-300 text-sm">{err}</div> : null}

                <div className="grid lg:grid-cols-2 gap-3">
                    {items.map((c) => (
                        <div key={c.id} className="rounded-2xl border border-white/10 bg-black/35 p-3">
                            <div className="flex items-start gap-3">
                                <div className="flex-1">
                                    <div className="text-white font-semibold">{c.name}</div>
                                    <div className="text-xs text-white/50 mt-1">
                                        kind={c.kind} · category={c.category ?? "-"} · {new Date(c.created_at).toLocaleString()}
                                    </div>
                                </div>
                            </div>
                            <div className="mt-3">
                                <JsonBox value={c.capability_meta} />
                            </div>
                        </div>
                    ))}
                </div>

                {!items.length ? <div className="text-white/60 mt-3">No capabilities yet.</div> : null}
            </Panel>
        </div>
    );
};
