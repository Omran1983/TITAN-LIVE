-- =========================================================
-- ReachX AI — Supabase Schema (V1) for existing JARVIS DB
-- Namespaced tables: reachx_*
-- =========================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =====================
-- TABLE: reachx_clients
-- =====================
CREATE TABLE IF NOT EXISTS public.reachx_clients (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name          text        NOT NULL,
    contact_email text        NOT NULL,
    phone         text,
    status        text        NOT NULL DEFAULT 'active', -- active / inactive
    created_at    timestamptz NOT NULL DEFAULT now()
);

-- =====================
-- TABLE: reachx_users
-- =====================
CREATE TABLE IF NOT EXISTS public.reachx_users (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id  uuid REFERENCES public.reachx_clients (id) ON DELETE SET NULL,
    name       text        NOT NULL,
    email      text        NOT NULL UNIQUE,
    role       text        NOT NULL DEFAULT 'client_user', -- admin / client_user
    created_at timestamptz NOT NULL DEFAULT now()
);

-- =====================
-- TABLE: reachx_campaigns
-- =====================
CREATE TABLE IF NOT EXISTS public.reachx_campaigns (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id        uuid NOT NULL REFERENCES public.reachx_clients (id) ON DELETE CASCADE,
    name             text        NOT NULL,
    target_industry  text,
    target_countries jsonb,           -- e.g. ["UAE","Qatar"]
    languages        jsonb,           -- e.g. ["en","fr","mfe","hi","ur"]
    status           text        NOT NULL DEFAULT 'draft', -- draft / running / paused / completed
    created_at       timestamptz NOT NULL DEFAULT now()
);

-- =====================
-- TABLE: reachx_leads
-- =====================
CREATE TABLE IF NOT EXISTS public.reachx_leads (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id     uuid NOT NULL REFERENCES public.reachx_clients (id) ON DELETE CASCADE,
    campaign_id   uuid NOT NULL REFERENCES public.reachx_campaigns (id) ON DELETE CASCADE,
    company_name  text        NOT NULL,
    contact_name  text,
    role          text,
    email         text,
    phone         text,
    website       text,
    country       text,
    industry      text,
    language      text,
    score         text        NOT NULL DEFAULT 'cold', -- hot / warm / cold
    source        text        NOT NULL DEFAULT 'web',  -- linkedin / web / manual / other
    status        text        NOT NULL DEFAULT 'new',  -- new / emailed / called / interested / not_interested / followup
    created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_reachx_leads_client_campaign
    ON public.reachx_leads (client_id, campaign_id);

CREATE INDEX IF NOT EXISTS idx_reachx_leads_status_created
    ON public.reachx_leads (status, created_at DESC);

-- =====================
-- TABLE: reachx_interactions
-- =====================
CREATE TABLE IF NOT EXISTS public.reachx_interactions (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id     uuid NOT NULL REFERENCES public.reachx_leads (id) ON DELETE CASCADE,
    campaign_id uuid NOT NULL REFERENCES public.reachx_campaigns (id) ON DELETE CASCADE,
    type        text        NOT NULL,                -- email / call / note / whatsapp
    channel_id  text,                                -- e.g. gmail, myt, sms
    direction   text        NOT NULL DEFAULT 'outbound', -- outbound / inbound
    language    text,
    summary     text,
    outcome     text,                                -- sent / opened / replied / no_answer / interested / not_interested / call_back
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_reachx_interactions_lead
    ON public.reachx_interactions (lead_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_reachx_interactions_campaign
    ON public.reachx_interactions (campaign_id, created_at DESC);

-- =====================
-- ENABLE RLS (we'll add policies later)
-- =====================
ALTER TABLE public.reachx_clients      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reachx_users        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reachx_campaigns    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reachx_leads        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reachx_interactions ENABLE ROW LEVEL SECURITY;
