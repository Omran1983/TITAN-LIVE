
import React, { useEffect, useMemo, useRef, useState } from "react";
import { apiPost } from "../lib/api";

type EnvelopeType = "RESULT" | "REFUSAL" | "PROPOSAL" | "QUESTION" | "ERROR" | "STREAM";
type Severity = "info" | "warning" | "critical";

type Envelope = {
    type: EnvelopeType;
    severity: Severity;
    message: string;
    data: any;
    evidence: Array<any>;
    next_actions: Array<{ action: string; hint?: string; example?: string }>;
    intent?: { id: string; status: string; created_at?: string };
    meta?: { ts: number };
};

type ConsoleEvent = {
    id: string;
    ts: number;
    kind: "COMMAND" | "ENVELOPE";
    command?: string;
    envelope?: Envelope;
};

function fmtTime(ts: number) {
    return new Date(ts).toLocaleTimeString([], { hour12: false });
}

function badgeClasses(sev: Severity) {
    if (sev === "critical") return "bg-red-500/15 text-red-200 border-red-500/30";
    if (sev === "warning") return "bg-amber-500/15 text-amber-200 border-amber-500/30";
    return "bg-emerald-500/15 text-emerald-200 border-emerald-500/30";
}

function typeClasses(t: EnvelopeType) {
    if (t === "ERROR") return "text-red-200";
    if (t === "REFUSAL") return "text-amber-200";
    if (t === "PROPOSAL") return "text-sky-200";
    if (t === "RESULT") return "text-emerald-200";
    return "text-zinc-200";
}

export const ConsolePage: React.FC = () => {
    const [command, setCommand] = useState("");
    const [events, setEvents] = useState<ConsoleEvent[]>(() => {
        const ts = Date.now();
        return [
            {
                id: "boot-1",
                ts,
                kind: "ENVELOPE",
                envelope: {
                    type: "RESULT",
                    severity: "info",
                    message: "TITAN OS Console [CONNECTED]",
                    data: { mode: "governed" },
                    evidence: [],
                    next_actions: [{ action: "help", example: "help" }],
                    meta: { ts },
                },
            },
            {
                id: "boot-2",
                ts: ts + 1,
                kind: "ENVELOPE",
                envelope: {
                    type: "RESULT",
                    severity: "info",
                    message: "Governance Module Online. Awaiting directives.",
                    data: {},
                    evidence: [],
                    next_actions: [{ action: "help", example: "help" }],
                    meta: { ts: ts + 1 },
                },
            },
        ];
    });

    const [loading, setLoading] = useState(false);
    const [pendingIntentId, setPendingIntentId] = useState<string | null>(null);

    const scrollRef = useRef<HTMLDivElement>(null);
    const inputRef = useRef<HTMLTextAreaElement>(null);

    useEffect(() => {
        scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: "smooth" });
    }, [events]);

    useEffect(() => {
        inputRef.current?.focus();
    }, []);

    const pushEvent = (ev: ConsoleEvent) => setEvents((prev) => [...prev, ev]);

    const runCommand = async () => {
        const text = command.trim();
        if (!text || loading) return;

        const ts = Date.now();
        pushEvent({ id: `cmd-${ts}`, ts, kind: "COMMAND", command: text });
        setCommand("");
        setLoading(true);

        try {
            const res = await apiPost<Envelope>("/api/console/execute", {
                command: text,
                intent_id: pendingIntentId || undefined,
            });

            // If backend created a new intent proposal, store it so next execute can use it
            if (res.type === "PROPOSAL" && res.intent?.id) {
                setPendingIntentId(res.intent.id);
            }

            // If result executed, clear pending intent (we’re done)
            if (res.type === "RESULT") {
                setPendingIntentId(null);
            }

            pushEvent({
                id: `env-${Date.now()}`,
                ts: Date.now(),
                kind: "ENVELOPE",
                envelope: res,
            });
        } catch (e: any) {
            const errEnv: Envelope = {
                type: "ERROR",
                severity: "critical",
                message: "Console request failed (network/backend).",
                data: { error: e?.message || String(e) },
                evidence: [],
                next_actions: [{ action: "status", example: "status" }],
                meta: { ts: Date.now() },
            };
            pushEvent({ id: `env-${Date.now()}`, ts: Date.now(), kind: "ENVELOPE", envelope: errEnv });
        } finally {
            setLoading(false);
        }
    };

    const approvePendingIntent = async () => {
        if (!pendingIntentId || loading) return;
        setLoading(true);
        const ts = Date.now();
        pushEvent({
            id: `cmd-${ts}`,
            ts,
            kind: "COMMAND",
            command: `approve intent ${pendingIntentId}`,
        });

        try {
            const res = await apiPost<Envelope>("/api/intents/approve", { intent_id: pendingIntentId });
            pushEvent({ id: `env-${Date.now()}`, ts: Date.now(), kind: "ENVELOPE", envelope: res });
            // keep intent id; execution still needs to be re-run to actually execute
        } catch (e: any) {
            pushEvent({
                id: `env-${Date.now()}`,
                ts: Date.now(),
                kind: "ENVELOPE",
                envelope: {
                    type: "ERROR",
                    severity: "critical",
                    message: "Intent approval failed.",
                    data: { error: e?.message || String(e) },
                    evidence: [],
                    next_actions: [],
                    meta: { ts: Date.now() },
                },
            });
        } finally {
            setLoading(false);
        }
    };

    const onKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
        if (e.key === "Enter" && !e.shiftKey) {
            e.preventDefault();
            runCommand();
        }
    };

    const copyAll = async () => {
        const text = events
            .map((ev) => {
                if (ev.kind === "COMMAND") return `${fmtTime(ev.ts)} > ${ev.command}`;
                const env = ev.envelope!;
                return `${fmtTime(ev.ts)} [${env.type}/${env.severity}] ${env.message} ${env.intent?.id ? `(intent=${env.intent.id})` : ""}`;
            })
            .join("\n");
        await navigator.clipboard.writeText(text);
    };

    const clear = () => {
        setEvents((prev) => prev.slice(0, 2));
        setPendingIntentId(null);
    };

    return (
        <div className="h-[calc(100vh-4rem)] w-full bg-[#0b1220] text-zinc-100">
            <div className="mx-auto max-w-[1400px] h-full px-4 py-4">
                <div className="h-full grid grid-cols-12 gap-4">
                    {/* LEFT: Explorer */}
                    <div className="col-span-12 md:col-span-3 rounded-2xl border border-white/10 bg-white/5 backdrop-blur p-4">
                        <div className="text-xs uppercase tracking-wider text-white/60 mb-3">Explorer</div>
                        <div className="space-y-2 text-sm">
                            {["titan_governor.py", "rules_v2.json", "active_intents.db", "system_log.txt"].map((f) => (
                                <div key={f} className="rounded-lg px-3 py-2 bg-white/5 border border-white/10">
                                    {f}
                                </div>
                            ))}
                        </div>

                        <div className="mt-6 text-xs uppercase tracking-wider text-white/60 mb-3">Quick commands</div>
                        <div className="grid grid-cols-2 gap-2">
                            {[
                                { label: "help", cmd: "help" },
                                { label: "status", cmd: "status" },
                                { label: "health", cmd: "health" },
                                { label: "logs tail", cmd: "logs tail 200" },
                            ].map((q) => (
                                <button
                                    key={q.label}
                                    className="rounded-lg border border-white/10 bg-white/5 hover:bg-white/10 px-3 py-2 text-sm text-left"
                                    onClick={() => setCommand(q.cmd)}
                                >
                                    {q.label}
                                </button>
                            ))}
                        </div>
                    </div>

                    {/* CENTER: Output stream */}
                    <div className="col-span-12 md:col-span-6 rounded-2xl border border-white/10 bg-white/5 backdrop-blur p-4 flex flex-col">
                        <div className="flex items-center justify-between gap-3 mb-3">
                            <div>
                                <div className="text-sm font-semibold">TITAN • Operator Console</div>
                                <div className="text-xs text-white/60">Output stream • chronological • audit-ready</div>
                            </div>
                            <div className="flex items-center gap-2">
                                <button onClick={copyAll} className="rounded-lg border border-white/10 bg-white/5 hover:bg-white/10 px-3 py-2 text-xs">
                                    Copy
                                </button>
                                <button onClick={clear} className="rounded-lg border border-white/10 bg-white/5 hover:bg-white/10 px-3 py-2 text-xs">
                                    Clear
                                </button>
                            </div>
                        </div>

                        <div ref={scrollRef} className="flex-1 overflow-y-auto rounded-xl border border-white/10 bg-black/30 p-3 font-mono text-sm">
                            {events.map((ev) => {
                                if (ev.kind === "COMMAND") {
                                    return (
                                        <div key={ev.id} className="flex gap-3 py-1">
                                            <div className="w-20 text-white/40 text-right select-none">{fmtTime(ev.ts)}</div>
                                            <div className="flex-1">
                                                <span className="text-sky-300">operator@titan</span>
                                                <span className="text-white/70">:$ </span>
                                                <span className="text-amber-200">{ev.command}</span>
                                            </div>
                                        </div>
                                    );
                                }

                                const env = ev.envelope!;
                                return (
                                    <div key={ev.id} className="flex gap-3 py-2">
                                        <div className="w-20 text-white/40 text-right select-none">{fmtTime(ev.ts)}</div>
                                        <div className="flex-1">
                                            <div className="flex items-center gap-2">
                                                <span className={`text-xs px-2 py-1 rounded border ${badgeClasses(env.severity)}`}>
                                                    {env.type}
                                                </span>
                                                {env.intent?.id && (
                                                    <span className="text-xs text-white/60">
                                                        intent: <span className="text-white/80">{env.intent.id}</span> ({env.intent.status})
                                                    </span>
                                                )}
                                            </div>

                                            <div className={`mt-1 ${typeClasses(env.type)}`}>{env.message}</div>

                                            {/* Always show "next_actions" for refusals/proposals */}
                                            {(env.type === "REFUSAL" || env.type === "PROPOSAL" || env.type === "ERROR") && env.next_actions?.length > 0 && (
                                                <div className="mt-2 text-xs text-white/70 space-y-1">
                                                    {env.next_actions.map((a, idx) => (
                                                        <div key={idx}>• {a.hint || a.action}{a.example ? ` — example: ${a.example}` : ""}</div>
                                                    ))}
                                                </div>
                                            )}

                                            {/* Evidence (truth source) */}
                                            {env.evidence?.length > 0 && (
                                                <details className="mt-2 text-xs">
                                                    <summary className="cursor-pointer text-white/60">evidence</summary>
                                                    <pre className="mt-2 whitespace-pre-wrap text-white/80 bg-white/5 border border-white/10 rounded-lg p-2">
                                                        {JSON.stringify(env.evidence, null, 2)}
                                                    </pre>
                                                </details>
                                            )}

                                            {/* Result data */}
                                            {env.type === "RESULT" && env.data && (
                                                <details className="mt-2 text-xs">
                                                    <summary className="cursor-pointer text-white/60">result</summary>
                                                    <pre className="mt-2 whitespace-pre-wrap text-white/80 bg-white/5 border border-white/10 rounded-lg p-2">
                                                        {JSON.stringify(env.data, null, 2)}
                                                    </pre>
                                                </details>
                                            )}
                                        </div>
                                    </div>
                                );
                            })}

                            {loading && (
                                <div className="flex gap-3 py-2 animate-pulse">
                                    <div className="w-20 text-white/40 text-right select-none">...</div>
                                    <div className="text-white/70">working…</div>
                                </div>
                            )}
                        </div>
                    </div>

                    {/* RIGHT: Input + Governance */}
                    <div className="col-span-12 md:col-span-3 rounded-2xl border border-white/10 bg-white/5 backdrop-blur p-4 flex flex-col gap-4">
                        <div>
                            <div className="text-xs uppercase tracking-wider text-white/60 mb-2">Terminal input</div>
                            <div className="text-xs text-white/50 mb-2">Enter = execute • Shift+Enter = newline • Esc = clear</div>
                            <div className="rounded-xl border border-white/10 bg-black/30 p-2">
                                <textarea
                                    ref={inputRef}
                                    value={command}
                                    onChange={(e) => setCommand(e.target.value)}
                                    onKeyDown={onKeyDown}
                                    className="w-full min-h-[120px] bg-transparent outline-none resize-none font-mono text-sm"
                                    placeholder="Type a command (e.g., status, health, logs tail 200, restart n8n, pull llama3)…"
                                    disabled={loading}
                                />
                            </div>
                            <div className="mt-2 flex justify-end gap-2">
                                <button
                                    className="rounded-lg border border-white/10 bg-white/5 hover:bg-white/10 px-3 py-2 text-xs"
                                    onClick={() => setCommand("")}
                                    disabled={loading}
                                >
                                    Clear
                                </button>
                                <button
                                    className="rounded-lg border border-white/10 bg-emerald-500/20 hover:bg-emerald-500/30 px-3 py-2 text-xs"
                                    onClick={runCommand}
                                    disabled={loading}
                                >
                                    Execute
                                </button>
                            </div>
                        </div>

                        <div className="rounded-xl border border-white/10 bg-black/30 p-3">
                            <div className="text-xs uppercase tracking-wider text-white/60 mb-2">Governance</div>

                            <div className="text-xs text-white/70">
                                Pending intent:{" "}
                                <span className="text-white/90">{pendingIntentId ? pendingIntentId : "none"}</span>
                            </div>

                            <div className="mt-2 flex gap-2">
                                <button
                                    className="flex-1 rounded-lg border border-white/10 bg-sky-500/20 hover:bg-sky-500/30 px-3 py-2 text-xs disabled:opacity-50"
                                    onClick={approvePendingIntent}
                                    disabled={loading || !pendingIntentId}
                                >
                                    Approve intent
                                </button>
                                <button
                                    className="flex-1 rounded-lg border border-white/10 bg-white/5 hover:bg-white/10 px-3 py-2 text-xs disabled:opacity-50"
                                    onClick={() => setPendingIntentId(null)}
                                    disabled={loading || !pendingIntentId}
                                >
                                    Drop
                                </button>
                            </div>

                            <div className="mt-3 text-xs text-white/50 leading-relaxed">
                                Rule: L2+ actions require an <span className="text-white/70">APPROVED</span> intent.
                                If no capability exists, TITAN must <span className="text-white/70">REFUSE</span> with next actions — never narrate.
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};
