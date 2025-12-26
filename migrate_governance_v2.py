
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
DB_URL = os.environ.get("JARVIS_DB_CONN")

# Strict Enterprise Schema
DDL = """
-- 1. KILL SWITCH (Global State)
DROP TABLE IF EXISTS az_killswitch;
CREATE TABLE az_killswitch (
    state BOOLEAN DEFAULT FALSE,
    set_by TEXT,
    set_at TIMESTAMPTZ DEFAULT NOW(),
    reason TEXT
);
-- Initialize (Default OFF)
INSERT INTO az_killswitch (state, set_by, reason) VALUES (FALSE, 'system', 'init');

-- 2. AUDIT LOG V2 (Forensics)
DROP TABLE IF EXISTS az_audit_log;
CREATE TABLE az_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ts TIMESTAMPTZ DEFAULT NOW(),
    actor_id TEXT,
    actor_role TEXT, -- L0-L4
    action TEXT NOT NULL,
    intent_id UUID,
    result TEXT, -- ALLOWED, DENIED, FAILED, SUCCEEDED
    deny_reason TEXT,
    request_ip INET,
    cooldown_hit BOOLEAN DEFAULT FALSE,
    killswitch_active BOOLEAN DEFAULT FALSE,
    payload JSONB DEFAULT '{}'::jsonb,
    exec_meta JSONB DEFAULT '{}'::jsonb
);
CREATE INDEX idx_audit_action ON az_audit_log(action);
CREATE INDEX idx_audit_ts ON az_audit_log(ts);
CREATE INDEX idx_audit_actor ON az_audit_log(actor_id);

-- 3. INTENT LEDGER (Decision Provenance)
DROP TABLE IF EXISTS az_intents;
CREATE TABLE az_intents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    agent_name TEXT,
    ui_intent TEXT, -- e.g. "action_proposal"
    proposed_action TEXT,
    risk_level TEXT, -- R1-R4
    status TEXT DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED, EXECUTED
    decision_metadata JSONB DEFAULT '{}'::jsonb, -- {approved_by, approved_at}
    execution_ref UUID, -- References az_audit_log(id)
    context JSONB DEFAULT '{}'::jsonb
);

-- 4. CAPABILITY METADATA (Library)
ALTER TABLE az_n8n_workflows ADD COLUMN IF NOT EXISTS capability_meta JSONB DEFAULT '{}'::jsonb;
"""

def migrate():
    print("Connecting to DB for Enterprise Migration...")
    conn = psycopg2.connect(DB_URL)
    cur = conn.cursor()
    
    try:
        print("Executing Enterprise DDL...")
        cur.execute(DDL)
        conn.commit()
        print("Schema V2 Applied Successfully.")
    except Exception as e:
        conn.rollback()
        print(f"Migration Failed: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    migrate()
