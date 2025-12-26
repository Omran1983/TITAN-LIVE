// src/pages/citadel/ConsoleAgents.tsx
import React, { useMemo, useState } from "react";
import { Panel } from "../../components/citadel/Panel";
import { JsonBox } from "../../components/citadel/JsonBox";
import { apiPost } from "../../lib/api";
import type { WebsiteReviewRequest, WebsiteReviewResponse } from "../../lib/types";

type ConsoleLine = {
    ts: number;
    level: "SYSTEM" | "USER" | "TITAN" | "ERROR";
    text: string;
};

function nowTs() {
    return Date.now();
}

export const ConsoleAgents: React.FC<{ token: string }> = ({ token }) => {
    const [url, setUrl] = useState("https://nabmakeup.com");
    const [intentId, setIntentId] = useState("");
    const [busy, setBusy] = useState(false);
    const [last, setLast] = useState<any>(null);

    const [lines, setLines] = useState<ConsoleLine[]>([
        { ts: nowTs(), level: "SYSTEM", text: "TITAN Console connected." },
        { ts: nowTs(), level: "SYSTEM", text: "Tip: Use Intents tab for L2+ operations." },
    ]);

    const push = (level: ConsoleLine["level"], text: string) => {
        setLines((p) => [...p, { ts: nowTs(), level, text }]);
    };

    const runWebsiteReview = async () => {
        setBusy(true);
        setLast(null);
        push("USER", `website_review url=${url} intent_id=${intentId || "-"}`);
        try {
            const payload: WebsiteReviewRequest = {
                url,
                intent_id: intentId.trim() ? intentId.trim() : null,
            };
            const res = await apiPost<WebsiteReviewResponse>("/api/agents/website-review", payload, { token });
            setLast(res);
            push("TITAN", `Review complete. verified=${String(res?.verify?.verified ?? res?.verify?.ok ?? false)}`);
        } catch (e: any) {
            push("ERROR", e.message || String(e));
        } finally {
            setBusy(false);
        }
    };

    const color = (lvl: ConsoleLine["level"]) => {
        switch (lvl) {
            case "SYSTEM":
                return "text-cyan-200";
            case "USER":
                return "text-orange-200";
            case "TITAN":
                return "text-emerald-200";
            case "ERROR":
                return "text-red-300";
            default:
                return "text-white/80";
        }
    };

    return (
        <div className="space-y-4">
            <Panel
                title="Website Review Agent"
                subtitle="Scrape → Store Artifact → Index Capability → Report (governed L1)"
                right={
                    <button
                        onClick={runWebsiteReview}
                        disabled={busy}
                        className="px-3 py-2 rounded-lg bg-white/10 border border-white/10 text-white/85 hover:bg-white/15"
                    >
                        {busy ? "Running..." : "Run"}
                    </button>
                }
            >
                <div className="grid md:grid-cols-2 gap-3">
                    <div>
                        <label className="text-xs text-white/50">URL</label>
                        <input
                            title="URL to review"
                            value={url}
                            onChange={(e) => setUrl(e.target.value)}
                            className="w-full mt-1 px-3 py-2 rounded-lg bg-white/5 border border-white/10 outline-none text-white/85"
                        />
                    </div>
                    <div>
                        <label className="text-xs text-white/50">Intent ID (optional)</label>
                        <input
                            value={intentId}
                            onChange={(e) => setIntentId(e.target.value)}
                            className="w-full mt-1 px-3 py-2 rounded-lg bg-white/5 border border-white/10 outline-none text-white/85"
                            placeholder="uuid (required for L2+; optional for L1)"
                        />
                    </div>
                </div>

                {last ? (
                    <div className="mt-4">
                        <div className="text-xs text-white/50 mb-1">Last Output</div>
                        <JsonBox value={last} />
                    </div>
                ) : null}
            </Panel>

            <Panel title="Console Log" subtitle="Evidence-first, no cosplay UI.">
                <div className="bg-black/40 border border-white/10 rounded-2xl p-3 max-h-[320px] overflow-auto">
                    {lines.map((l, idx) => (
                        <div key={idx} className="text-xs leading-5 flex gap-3">
                            <div className="text-white/35 w-24 shrink-0">
                                {new Date(l.ts).toLocaleTimeString([], { hour12: false })}
                            </div>
                            <div className={`${color(l.level)} whitespace-pre-wrap break-words`}>
                                <span className="text-white/40 mr-2">[{l.level}]</span>
                                {l.text}
                            </div>
                        </div>
                    ))}
                </div>
            </Panel>
        </div>
    );
};
