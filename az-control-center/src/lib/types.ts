// src/lib/types.ts
export type Authority = "L0" | "L1" | "L2" | "L3" | "L4";

export type HealthResponse = {
    service: { ok: boolean; service: string; ts: number };
    db: { ok: boolean; latency_ms?: number; now?: string; error?: string };
    killswitch: boolean;
    registry_keys: string[];
};

export type IntentCreateRequest = {
    agent_name?: string;
    ui_intent?: string;
    proposed_action: string;
    confidence?: number;
    risk_level?: Authority;
    explanation?: string;
    decision_metadata?: Record<string, any>;
};

export type IntentCreateResponse = {
    ok: boolean;
    intent_id: string;
};

export type IntentApproveResponse = {
    ok: boolean;
    intent_id: string;
    status: "APPROVED";
};

export type ActionRunRequest = {
    action_key: string;
    intent_id?: string | null;
};

export type ActionRunResponse = {
    ok: boolean;
    action_key?: string;
    data?: any;
    error?: string;
};

export type WebsiteReviewRequest = {
    url: string;
    intent_id?: string | null;
};

export type WebsiteReviewResponse = {
    ok: boolean;
    agent: string;
    observe?: any;
    acquire?: any;
    persist?: any;
    index?: any;
    act?: any;
    verify?: any;
    error?: string;
};

export type CapabilitiesResponse = {
    ok: boolean;
    items: Array<{
        id: string;
        created_at: string;
        kind: string;
        name: string;
        category: string | null;
        capability_meta: any;
        source_artifact_id: string | null;
    }>;
};

export type AuditLogItem = {
    id: string;
    created_at: string;
    actor: string;
    actor_id: string;
    action_key: string;
    intent_id: string | null;
    risk_level: string;
    authority_required: string;
    authority_used: string;
    ok: boolean;
    request: any;
    result: any;
    error: string | null;
};
