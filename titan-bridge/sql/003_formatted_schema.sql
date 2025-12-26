-- TITAN BRIDGE v3 SCHEMA (az_*)
-- COPY ALL OF THIS (Ctrl+A, Ctrl+C) AND PASTE INTO SUPABASE SQL EDITOR

create extension if not exists "pgcrypto";

do $$ begin
  create type az_command_state as enum ('QUEUED','CLAIMED','RUNNING','VERIFYING','DONE','FAILED','CANCELLED');
exception when duplicate_object then null; end $$;

do $$ begin
  create type az_severity as enum ('info','warn','critical');
exception when duplicate_object then null; end $$;

do $$ begin
  create type az_agent_status as enum ('IDLE','RUNNING','ERROR','OFFLINE');
exception when duplicate_object then null; end $$;

-- Commands queue
create table if not exists public.az_commands (
  command_id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  origin text not null default 'telegram',
  requested_by text not null default 'founder',
  source_chat_id text null,
  source_message_id text null,
  title text not null,
  intent text not null,
  objective text not null,
  targets jsonb not null default '[]'::jsonb,
  inputs jsonb not null default '{}'::jsonb,
  constraints jsonb not null default '[]'::jsonb,
  priority int not null default 1,
  state az_command_state not null default 'QUEUED',
  state_reason text null,
  assigned_agent_id text null,
  claimed_at timestamptz null,
  started_at timestamptz null,
  finished_at timestamptz null,
  progress int not null default 0,
  last_heartbeat_at timestamptz null,
  result jsonb null,
  error jsonb null
);

create index if not exists az_commands_state_idx on public.az_commands(state, priority, created_at);

-- Events
create table if not exists public.az_events (
  event_id bigserial primary key,
  ts timestamptz not null default now(),
  source text not null,
  command_id uuid null references public.az_commands(command_id) on delete set null,
  severity az_severity not null default 'info',
  event_type text not null,
  message text not null,
  payload jsonb not null default '{}'::jsonb
);

-- Health snapshots
create table if not exists public.az_health_snapshots (
  agent_id text primary key,
  ts timestamptz not null default now(),
  status az_agent_status not null,
  current_command_id uuid null references public.az_commands(command_id) on delete set null,
  last_error text null,
  metrics jsonb not null default '{}'::jsonb
);

-- Telegram outbox
create table if not exists public.az_telegram_outbox (
  outbox_id bigserial primary key,
  ts timestamptz not null default now(),
  chat_id text not null,
  message text not null,
  sent boolean not null default false,
  sent_at timestamptz null,
  error text null
);
