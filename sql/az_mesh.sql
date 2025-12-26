-- JARVIS MESH CONFIGURATION TABLES (The Envoy Control Plane)

-- 1) MESH AGENTS (Who is in the network?)
create table if not exists az_mesh_agents (
  id uuid primary key default gen_random_uuid(),
  agent_name text not null unique,         -- e.g. 'Jarvis-CodeAgent', 'Jarvis-NotifyWorker'
  description text,
  status text not null default 'active',   -- 'active' | 'disabled'
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2) MESH ROUTES (Who talks to whom?)
create table if not exists az_mesh_routes (
  id uuid primary key default gen_random_uuid(),
  source_agent text not null,              -- e.g. 'Jarvis-CommandsApi'
  target_agent text not null,              -- e.g. 'Jarvis-CodeAgent'
  route_key text not null,                 -- e.g. 'reachx.code.patch'
  
  -- Resilience Config
  max_retries int not null default 2,
  timeout_ms int not null default 30000,
  backoff_strategy text not null default 'exponential',
  circuit_breaker_threshold int not null default 5,    -- failures before open
  
  is_enabled boolean not null default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 3) MESH ENDPOINTS (Where do they live?)
create table if not exists az_mesh_endpoints (
  id uuid primary key default gen_random_uuid(),
  agent_name text not null,                -- matches az_mesh_agents.agent_name
  endpoint_url text not null,              -- e.g. 'http://127.0.0.1:5061'
  zone text default 'local',               -- future: 'local' | 'cloud' | 'backup'
  
  -- Health Status
  is_healthy boolean not null default true,
  last_health_check timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- RLS POLICIES (Services Full Access)
alter table az_mesh_agents enable row level security;
alter table az_mesh_routes enable row level security;
alter table az_mesh_endpoints enable row level security;

create policy "Service Role Full Access Agents" on az_mesh_agents for all to service_role using (true) with check (true);
create policy "Service Role Full Access Routes" on az_mesh_routes for all to service_role using (true) with check (true);
create policy "Service Role Full Access Endpoints" on az_mesh_endpoints for all to service_role using (true) with check (true);
