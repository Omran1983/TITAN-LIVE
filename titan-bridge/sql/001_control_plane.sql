-- 001_control_plane.sql
-- TITAN Bridge v1: Commands, Events, Agents, Health, Projects

-- Enable uuid generation
create extension if not exists "pgcrypto";

-- ----------------------------
-- ENUMS
-- ----------------------------
do $$ begin
  create type az_command_state as enum (
    'QUEUED',
    'CLAIMED',
    'RUNNING',
    'VERIFYING',
    'DONE',
    'FAILED',
    'NEEDS_APPROVAL',
    'CANCELLED'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type az_severity as enum ('info','warn','critical');
exception when duplicate_object then null; end $$;

do $$ begin
  create type az_agent_status as enum ('IDLE','RUNNING','ERROR','OFFLINE');
exception when duplicate_object then null; end $$;

do $$ begin
  create type az_agent_transport as enum ('LOCAL','HTTP');
exception when duplicate_object then null; end $$;

do $$ begin
  create type az_authority_level as enum ('L0','L1','L2','L3','L4');
exception when duplicate_object then null; end $$;

-- ----------------------------
-- AGENTS REGISTRY
-- ----------------------------
create table if not exists public.az_agents (
  agent_id text primary key,
  name text not null,
  transport az_agent_transport not null default 'LOCAL',
  http_endpoint text null, -- if transport = HTTP
  local_entrypoint text null, -- if transport = LOCAL (python module path or script)
  capabilities jsonb not null default '[]'::jsonb, -- e.g. ["inspector","doctor","verifier"]
  max_concurrency int not null default 1,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists az_agents_enabled_idx on public.az_agents(enabled);

-- ----------------------------
-- COMMANDS QUEUE
-- ----------------------------
create table if not exists public.az_commands (
  command_id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  origin text not null default 'laptop', -- laptop|phone|api
  requested_by text not null default 'founder',
  title text not null,
  intent text not null, -- bugfix|deploy|report|research|...
  objective text not null,

  targets jsonb not null default '[]'::jsonb, -- ["Doctor","Inspector"]
  constraints jsonb not null default '[]'::jsonb,
  inputs jsonb not null default '{}'::jsonb,

  definition_of_done jsonb not null default '[]'::jsonb,
  notify jsonb not null default '[]'::jsonb, -- ["dashboard","whatsapp"]

  authority_required az_authority_level not null default 'L1',
  approved boolean not null default false,
  approved_by text null,
  approved_at timestamptz null,

  priority int not null default 2, -- 0=P0,1=P1,2=P2,3=P3
  state az_command_state not null default 'QUEUED',
  state_reason text null,

  assigned_agent_id text null references public.az_agents(agent_id),
  claimed_at timestamptz null,
  started_at timestamptz null,
  finished_at timestamptz null,

  progress int not null default 0, -- 0..100
  last_heartbeat_at timestamptz null,

  result jsonb null,
  error jsonb null
);

create index if not exists az_commands_state_idx on public.az_commands(state, priority, created_at);
create index if not exists az_commands_assigned_idx on public.az_commands(assigned_agent_id, state);
create index if not exists az_commands_updated_idx on public.az_commands(updated_at desc);

-- ----------------------------
-- EVENTS / TELEMETRY STREAM
-- ----------------------------
create table if not exists public.az_events (
  event_id bigserial primary key,
  ts timestamptz not null default now(),

  source text not null, -- agent_id | "control_plane"
  command_id uuid null references public.az_commands(command_id) on delete set null,

  severity az_severity not null default 'info',
  event_type text not null, -- heartbeat|log|state_change|error|metric
  message text not null,

  payload jsonb not null default '{}'::jsonb
);

create index if not exists az_events_ts_idx on public.az_events(ts desc);
create index if not exists az_events_command_idx on public.az_events(command_id, ts desc);
create index if not exists az_events_source_idx on public.az_events(source, ts desc);

-- ----------------------------
-- HEALTH SNAPSHOTS (optional convenience table)
-- ----------------------------
create table if not exists public.az_health_snapshots (
  agent_id text primary key references public.az_agents(agent_id) on delete cascade,
  ts timestamptz not null default now(),
  status az_agent_status not null,
  current_command_id uuid null references public.az_commands(command_id) on delete set null,
  last_error text null,
  metrics jsonb not null default '{}'::jsonb
);

-- ----------------------------
-- PROJECTS (optional, for “project health” briefs)
-- ----------------------------
create table if not exists public.az_projects (
  project_id text primary key,
  name text not null,
  status text not null default 'active', -- active|paused|done
  owner text null,
  tags jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ----------------------------
-- TRIGGERS to keep updated_at fresh
-- ----------------------------
create or replace function public.az_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists trg_az_agents_touch on public.az_agents;
create trigger trg_az_agents_touch
before update on public.az_agents
for each row execute function public.az_touch_updated_at();

drop trigger if exists trg_az_commands_touch on public.az_commands;
create trigger trg_az_commands_touch
before update on public.az_commands
for each row execute function public.az_touch_updated_at();

drop trigger if exists trg_az_projects_touch on public.az_projects;
create trigger trg_az_projects_touch
before update on public.az_projects
for each row execute function public.az_touch_updated_at();
