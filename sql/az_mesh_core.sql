-- az_mesh_agents: one row per logical agent (CodeAgent, Watchdog, CommandsApi, etc.)
create table if not exists public.az_mesh_agents (
  agent_name  text primary key,
  status      text not null default 'unknown', -- active / error / offline
  last_seen   timestamptz not null default now(),
  latency_ms  integer not null default 0,
  extra       jsonb
);

-- az_mesh_endpoints: HTTP endpoints and ports health (CommandsApi, Citadel, MeshProxy, etc.)
create table if not exists public.az_mesh_endpoints (
  name          text primary key,
  url           text not null,
  status        text not null default 'unknown', -- ok / down / slow / error
  last_checked  timestamptz not null default now(),
  latency_ms    integer not null default 0,
  last_error    text
);

-- az_reflex_log: history of reflex actions (auto-restarts, suppressions, etc.)
create table if not exists public.az_reflex_log (
  id           bigserial primary key,
  created_at   timestamptz not null default now(),
  agent_name   text,
  action       text,
  reason       text,
  details      jsonb
);
