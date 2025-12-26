-- [HASH] FIX_SCHEMA_RESET_V3
-- WARNING: THIS SCRIPT DROPS EXISTING BRIDGE TABLES TO ENSURE A CLEAN INSTALL
-- RUN THIS ONLY IF YOU ARE OKAY LOSING OLD 'az_commands' HISTORY.

BEGIN;

-- 1. CLEANUP (Drop old tables/types to prevent conflicts)
DROP TABLE IF EXISTS public.az_events CASCADE;
DROP TABLE IF EXISTS public.az_commands CASCADE;
DROP TABLE IF EXISTS public.az_health_snapshots CASCADE;
DROP TABLE IF EXISTS public.az_telegram_outbox CASCADE;

-- Drop enums carefully (cascade will handle table dependencies, but we want to redefine them)
DROP TYPE IF EXISTS az_command_state CASCADE;
DROP TYPE IF EXISTS az_severity CASCADE;
DROP TYPE IF EXISTS az_agent_status CASCADE;

-- 2. RE-CREATE EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 3. RE-DEFINE TYPES
DO $$ BEGIN
    CREATE TYPE az_command_state AS ENUM (
        'QUEUED','CLAIMED','RUNNING','VERIFYING','DONE','FAILED','CANCELLED'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE az_severity AS ENUM ('info','warn','critical');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE az_agent_status AS ENUM ('IDLE','RUNNING','ERROR','OFFLINE');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 4. RE-CREATE TABLES

-- az_commands
CREATE TABLE public.az_commands (
    command_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    origin text NOT NULL DEFAULT 'telegram',
    requested_by text NOT NULL DEFAULT 'founder',

    source_chat_id text NULL,
    source_message_id text NULL,

    title text NOT NULL,
    intent text NOT NULL,
    objective text NOT NULL,

    targets jsonb NOT NULL DEFAULT '[]'::jsonb,
    inputs jsonb NOT NULL DEFAULT '{}'::jsonb,
    constraints jsonb NOT NULL DEFAULT '[]'::jsonb,

    priority int NOT NULL DEFAULT 1,
    state az_command_state NOT NULL DEFAULT 'QUEUED',
    state_reason text NULL,

    assigned_agent_id text NULL,
    claimed_at timestamptz NULL,
    started_at timestamptz NULL,
    finished_at timestamptz NULL,

    progress int NOT NULL DEFAULT 0,
    last_heartbeat_at timestamptz NULL,

    result jsonb NULL,
    error jsonb NULL
);

CREATE INDEX az_commands_state_idx ON public.az_commands(state, priority, created_at);
CREATE INDEX az_commands_updated_idx ON public.az_commands(updated_at DESC);
CREATE INDEX az_commands_chat_idx ON public.az_commands(source_chat_id, updated_at DESC);

-- az_events
CREATE TABLE public.az_events (
    event_id bigserial PRIMARY KEY,
    ts timestamptz NOT NULL DEFAULT now(),
    source text NOT NULL,
    command_id uuid NULL REFERENCES public.az_commands(command_id) ON DELETE SET NULL,
    severity az_severity NOT NULL DEFAULT 'info',
    event_type text NOT NULL,
    message text NOT NULL,
    payload jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX az_events_ts_idx ON public.az_events(ts DESC);
CREATE INDEX az_events_command_idx ON public.az_events(command_id, ts DESC);

-- az_health_snapshots
CREATE TABLE public.az_health_snapshots (
    agent_id text PRIMARY KEY,
    ts timestamptz NOT NULL DEFAULT now(),
    status az_agent_status NOT NULL,
    current_command_id uuid NULL REFERENCES public.az_commands(command_id) ON DELETE SET NULL,
    last_error text NULL,
    metrics jsonb NOT NULL DEFAULT '{}'::jsonb
);

-- az_telegram_outbox
CREATE TABLE public.az_telegram_outbox (
    outbox_id bigserial PRIMARY KEY,
    ts timestamptz NOT NULL DEFAULT now(),
    chat_id text NOT NULL,
    message text NOT NULL,
    sent boolean NOT NULL DEFAULT false,
    sent_at timestamptz NULL,
    error text NULL
);

CREATE INDEX az_telegram_outbox_unsent_idx ON public.az_telegram_outbox(sent, ts);

-- 5. RE-CREATE TRIGGERS
CREATE OR REPLACE FUNCTION public.az_touch_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END $$;

CREATE TRIGGER trg_az_commands_touch
BEFORE UPDATE ON public.az_commands
FOR EACH ROW EXECUTE FUNCTION public.az_touch_updated_at();

COMMIT;
