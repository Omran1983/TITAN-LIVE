-- Protocol: A2UI (Agent-to-UI)
-- Purpose: Store structured intents intended for the Control Center

CREATE TABLE IF NOT EXISTS az_ui_intents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id TEXT NOT NULL,
    intent_type TEXT NOT NULL, -- e.g. decision_review, data_preview
    risk_level TEXT DEFAULT 'low', -- low, medium, high, critical
    payload JSONB NOT NULL, -- Full JSON content of the intent (title, summary, actions)
    status TEXT DEFAULT 'pending', -- pending, approved, rejected, expired
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    resolved_by TEXT
);

-- Index for finding pending decisions quickly
CREATE INDEX IF NOT EXISTS idx_ui_intents_status ON az_ui_intents (status);
CREATE INDEX IF NOT EXISTS idx_ui_intents_agent ON az_ui_intents (agent_id);
