import { useEffect, useState } from "react";
import { apiGet } from "../lib/api";

type StatusResp = {
    ok: boolean;
    system?: {
        service?: string;
        time?: number;
        pid?: number;
        python?: string;
        port?: number;
    };
    health?: Record<string, unknown>;
};

export const SystemPage = () => {
    const [data, setData] = useState<StatusResp | null>(null);
    const [err, setErr] = useState<string>("");

    useEffect(() => {
        apiGet<StatusResp>("/api/status")
            .then(setData)
            .catch((e) => setErr(e?.message ?? "Failed"));
    }, []);

    return (
        <div className="p-4">
            <h2>System</h2>
            {err && <div className="text-red">{err}</div>}
            {!data && !err && <div>Loading…</div>}

            {data?.system && (
                <div className="mt-3">
                    <div><b>Service:</b> {data.system.service}</div>
                    <div><b>PID:</b> {data.system.pid}</div>
                    <div><b>Port:</b> {data.system.port}</div>
                    <div><b>Python:</b> {data.system.python || "—"}</div>
                    <div><b>Time:</b> {data.system.time ? new Date(data.system.time * 1000).toLocaleString() : "—"}</div>
                </div>
            )}

            {data?.health && (
                <div className="mt-4">
                    <h3>Health (summary)</h3>
                    <pre className="code-block">
                        {JSON.stringify(data.health, null, 2)}
                    </pre>
                </div>
            )}
        </div>
    );
}
