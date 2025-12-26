-- Enable UUID generation if available
-- For Supabase: usually already present
create extension if not exists pgcrypto;

-- 1) Intents Ledger
create table if not exists az_intents (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  agent_name text,
  ui_intent text,              -- action_proposal | agent_run | remediation
  proposed_action text,        -- e.g. titan:restart_n8n
  confidence float,
  risk_level text,             -- L0-L4
  explanation text,
  status text default 'PENDING', -- PENDING | APPROVED | REJECTED | EXECUTED
  decision_metadata jsonb default '{}'::jsonb
);

create index if not exists idx_az_intents_created_at on az_intents(created_at desc);
create index if not exists idx_az_intents_status on az_intents(status);

-- 2) Audit Log (every governed action / agent run)
create table if not exists az_audit_log (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  actor text,                     -- user | agent | system
  actor_id text,
  action_key text,                -- registry key, e.g. titan:website_review
  intent_id uuid references az_intents(id),
  risk_level text,
  authority_required text,
  authority_used text,
  ok boolean default false,
  request jsonb default '{}'::jsonb,
  result jsonb default '{}'::jsonb,
  error text
);

create index if not exists idx_az_audit_log_created_at on az_audit_log(created_at desc);
create index if not exists idx_az_audit_log_action_key on az_audit_log(action_key);

-- 3) Artifacts (raw + parsed + provenance)
create table if not exists az_artifacts (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  source_type text not null,      -- website | repo | file | api | log
  source_uri text not null,
  content_hash text not null,
  raw_path text not null,
  parsed jsonb default '{}'::jsonb,
  meta jsonb default '{}'::jsonb
);

create unique index if not exists uq_az_artifacts_hash on az_artifacts(content_hash);

-- 4) Capabilities registry (tools/repos/flows “cards”)
create table if not exists az_capabilities (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  kind text not null,              -- tool | repo | n8n_workflow | agent
  name text not null,
  category text,
  capability_meta jsonb not null,  -- inputs/outputs/runtime/deps etc.
  source_artifact_id uuid references az_artifacts(id)
);

create index if not exists idx_az_capabilities_kind on az_capabilities(kind);
create index if not exists idx_az_capabilities_category on az_capabilities(category);

-- 5) Incidents + Remediations (self-heal evidence)
create table if not exists az_incidents (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  kind text not null,              -- service_down | api_error | db_error | disk_low
  severity text not null,          -- L1-L4
  summary text not null,
  evidence jsonb default '{}'::jsonb,
  status text default 'OPEN'       -- OPEN | FIXED | IGNORED
);

create table if not exists az_remediations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  incident_id uuid references az_incidents(id),
  action_key text not null,
  intent_id uuid references az_intents(id),
  ok boolean default false,
  before_state jsonb default '{}'::jsonb,
  after_state jsonb default '{}'::jsonb,
  error text
);
