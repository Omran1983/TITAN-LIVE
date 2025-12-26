-- AZ REFLEX ENGINE SCHEMA
-- The "Immune System" Memory

-- Force Clean Slate (Fixes "column does not exist" errors if stale)
drop table if exists az_reflex_firings; -- Legacy table causing dependency
drop table if exists az_reflex_actions;
drop table if exists az_reflex_rules;
drop table if exists az_reflex_incidents;

-- 1. Incidents (The Sickness)
-- Tracks persistent failures escalated by the Watchdog
create table az_reflex_incidents (
  id uuid primary key default gen_random_uuid(),
  component text not null, -- e.g. 'Jarvis-CommandsApi'
  error_signature text,    -- e.g. '500 Internal Server Error' or 'Process Crash'
  status text check (status in ('open', 'investigating', 'resolved', 'escalated')) default 'open',
  severity text check (severity in ('low', 'medium', 'high', 'critical')) default 'medium',
  diagnosis text,          -- AI's theory on root cause
  created_at timestamptz default now(),
  resolved_at timestamptz
);

-- 2. Rules (The Medical Knowledge)
-- Heuristics and Policies for auto-healing
create table if not exists az_reflex_rules (
  id uuid primary key default gen_random_uuid(),
  error_pattern text not null, -- Regex or keyword to match in logs/error
  action_plan jsonb not null,  -- e.g. {"action": "restart", "retry_count": 3} or {"action": "rollback"}
  priority int default 10,
  created_at timestamptz default now()
);

-- 3. Actions (The Treatment Log)
-- Record of every autonomy action taken
create table if not exists az_reflex_actions (
  id uuid primary key default gen_random_uuid(),
  incident_id uuid references az_reflex_incidents(id),
  action_type text not null,   -- 'restart', 'rollback', 'clear_cache', 'alert_user'
  details jsonb,               -- Parameters used
  result text check (result in ('success', 'failure', 'pending')),
  executed_at timestamptz default now()
);

-- Seed some basic Reflex Rules
insert into az_reflex_rules (error_pattern, action_plan, priority) values
('Connection refused', '{"action": "restart_service", "target": "component"}', 10),
('Out of Memory', '{"action": "kill_process", "target": "component"}', 20),
('Module not found', '{"action": "alert_user", "message": "Dependency missing"}', 10);
