-- TITAN CONTROL PLANE - SUPABASE SCHEMA v1.0
-- Based on: TITAN Authoritative Hierarchy (Text-Only)

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. AUTHORITY LEVELS & ROLES (Enums/Lookups)
-- -----------------------------------------------------------------------------

-- Authority Levels (L0 - L4)
DO $$ BEGIN
    CREATE TYPE authority_level_enum AS ENUM ('L0', 'L1', 'L2', 'L3', 'L4');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
-- L0: Supreme (Principal)
-- L1: Strategic (Directors)
-- L2: Managerial (Agents)
-- L3: Operational (Bots - High Risk)
-- L4: Task (Bots - Low Risk)

-- System Core Roles
DO $$ BEGIN
    CREATE TYPE core_system_enum AS ENUM ('TITAN', 'JARVIS', 'AION_ZERO');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- -----------------------------------------------------------------------------
-- 2. DIRECTORS (Level 1)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS titan_directors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,          -- e.g., "Director of Strategy"
    domain_description TEXT,      -- e.g., "Growth & Map"
    human_in_loop BOOLEAN DEFAULT TRUE,
    authority_level authority_level_enum DEFAULT 'L1',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed Data: The 6 Board Members (Upsert based on title)
INSERT INTO titan_directors (title, domain_description) VALUES
('Chief of Staff / Strategy Director', 'Strategy alignment, priority arbitration, cross-domain coordination'),
('Finance & Risk Director', 'Budgeting, ROI tracking, financial controls, risk exposure'),
('Growth & Revenue Director', 'Sales systems, funnels, partnerships, monetization'),
('Product & Delivery Director', 'Product roadmap, execution quality, delivery velocity'),
('Legal & Compliance Director', 'Regulatory compliance, contracts, audit readiness'),
('Security & Infrastructure Director', 'Infrastructure health, access control, system resilience')
ON CONFLICT DO NOTHING; -- Ensure we don't duplicate if running multiple times

-- -----------------------------------------------------------------------------
-- 3. MANAGER AGENTS (Level 4)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS titan_manager_agents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    director_id UUID REFERENCES titan_directors(id),
    name TEXT NOT NULL,           -- e.g., "Operations Manager Agent"
    system_role TEXT,             -- e.g., "Domain Owner"
    authority_level authority_level_enum DEFAULT 'L2',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 4. BOT FLEET (Level 5 & Level 3 Autonomy)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS titan_bots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    manager_agent_id UUID REFERENCES titan_manager_agents(id), -- Nullable for Level 3 Autonomy bots if they report directly to System
    name TEXT NOT NULL,           -- e.g., "HealBot", "ProspectingBot"
    function_description TEXT,
    is_stateful BOOLEAN DEFAULT FALSE, -- Bots are stateless by default
    uses_tools JSONB,             -- List of tools this bot is allowed to access via JARVIS
    authority_level authority_level_enum DEFAULT 'L4',
    status TEXT DEFAULT 'IDLE',   -- IDLE, RUNNING, ERROR, MAINTENANCE
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 5. EXECUTION PERMITS (AION-ZERO GATEWAY)
-- -----------------------------------------------------------------------------
-- Every significant action by a Bot or Agent requires a Permit.
CREATE TABLE IF NOT EXISTS titan_execution_permits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requestor_id UUID NOT NULL,   -- ID of Bot or Agent
    requestor_type TEXT NOT NULL, -- 'BOT' or 'AGENT'
    action_intent TEXT NOT NULL,  -- Description of what they want to do
    target_resource TEXT,         -- e.g., "Database Table: Users", "API: Stripe"
    risk_score INT DEFAULT 0,     -- Calculated by TITAN
    status TEXT DEFAULT 'PENDING',-- PENDING, APPROVED, REJECTED, REVOKED
    approved_by TEXT,             -- 'TITAN_AUTO' or Human Name
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

-- -----------------------------------------------------------------------------
-- 6. AUDIT LOG (IMMUTABLE MEMORY)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS titan_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    actor_id UUID,
    actor_name TEXT,
    event_type TEXT,
    details JSONB,
    hash TEXT -- For tamper-evidence (future implementation)
);

-- -----------------------------------------------------------------------------
-- VIEWS FOR DASHBOARD
-- -----------------------------------------------------------------------------
-- View: Hierarchy Tree (Drop and Recreate to ensure freshness)
DROP VIEW IF EXISTS view_titan_hierarchy;
CREATE VIEW view_titan_hierarchy AS
SELECT 
    d.title as director,
    m.name as manager_agent,
    b.name as bot_name,
    b.status as bot_status
FROM titan_directors d
LEFT JOIN titan_manager_agents m ON m.director_id = d.id
LEFT JOIN titan_bots b ON b.manager_agent_id = m.id;
