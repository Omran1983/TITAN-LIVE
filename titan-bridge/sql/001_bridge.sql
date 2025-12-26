create extension if not exists "pgcrypto";

do $$ begin
  create type az_command_state as enum (
    'QUEUED','CLAIMED','RUNNING','VERIFYING','DONE','FAILED','CANCELLED'
  );
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
  intent text not null,                  -- project.run | shell.powershell | shell.cmd | shell.python | shell.node | shell.docker | status
  objective text not null,

  targets jsonb not null default '[]'::jsonb,
  inputs jsonb not null default '{}'::jsonb,
  constraints jsonb not null default '[]'::jsonb,

  priority int not null default 1,       -- 0..3
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
create index if not exists az_commands_updated_idx on public.az_commands(updated_at desc);
create index if not exists az_commands_chat_idx on public.az_commands(source_chat_id, updated_at desc);

-- Events
create table if not exists public.az_events (
  event_id bigserial primary key,
  ts timestamptz not null default now(),
  source text not null, -- agent_id | "control_plane"
  command_id uuid null references public.az_commands(command_id) on delete set null,
  severity az_severity not null default 'info',
  event_type text not null, -- heartbeat|log|state_change|metric|error
  message text not null,
  payload jsonb not null default '{}'::jsonb
);

create index if not exists az_events_ts_idx on public.az_events(ts desc);
create index if not exists az_events_command_idx on public.az_events(command_id, ts desc);

-- Health snapshots (upserted by runner)
create table if not exists public.az_health_snapshots (
  agent_id text primary key,
  ts timestamptz not null default now(),
  status az_agent_status not null,
  current_command_id uuid null references public.az_commands(command_id) on delete set null,
  last_error text null,
  metrics jsonb not null default '{}'::jsonb
);

-- Optional Telegram outbox (audit)
create table if not exists public.az_telegram_outbox (
  outbox_id bigserial primary key,
  ts timestamptz not null default now(),
  chat_id text not null,
  message text not null,
  sent boolean not null default false,
  sent_at timestamptz null,
  error text null
);

create index if not exists az_telegram_outbox_unsent_idx on public.az_telegram_outbox(sent, ts);

-- updated_at trigger
create or replace function public.az_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists trg_az_commands_touch on public.az_commands;
create trigger trg_az_commands_touch
before update on public.az_commands
for each row execute function public.az_touch_updated_at();
