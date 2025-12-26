// src/pages/citadel/HealthPage.tsx
import React, { useEffect, useState } from "react";
import { apiGet } from "../../lib/api";
import type { HealthResponse } from "../../lib/types";
import { Panel } from "../../components/citadel/Panel";
import { JsonBox } from "../../components/citadel/JsonBox";

export const HealthPage: React.FC<{ token: string }> = ({ token }) => {
    const [data, setData] = useState<HealthResponse | null>(null);
    const [err, setErr] = useState<string | null>(null);
    const [loading, setLoading] = useState(false);

    const load = async () => {
        setLoading(true);
        setErr(null);
        try {
            const r = await apiGet<HealthResponse>("/api/health", { token });
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

    return (
        <div className="space-y-4">
            <Panel
                title="System Health"
                subtitle="TITAN server + DB ping + killswitch + registry keys"
                right={
                    <button
                        onClick={load}
                        className="px-3 py-2 rounded-lg bg-white/10 border border-white/10 text-white/80 hover:bg-white/15"
                        disabled={loading}
                    >
                        {loading ? "Refreshing..." : "Refresh"}
                    </button>
                }
            >
                {err ? <div className="text-red-300 text-sm">{err}</div> : null}
                {data ? <JsonBox value={data} /> : <div className="text-white/60">No data yet.</div>}
            </Panel>
        </div>
    );
};
