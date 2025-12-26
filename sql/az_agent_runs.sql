-- Create table for tracking agent runs
create table if not exists az_agent_runs (
  id           uuid primary key default gen_random_uuid(),
  run_id       uuid,             -- from the Command
  agent_name   text not null,
  mission_id   uuid,             -- nullable
  status       text not null,    -- 'success' | 'soft_fail' | 'hard_fail'
  severity     text not null,    -- 'info' | 'warning' | 'error'
  started_at   timestamptz not null,
  finished_at  timestamptz not null,
  duration_ms  integer generated always as
               (CAST(EXTRACT(EPOCH FROM (finished_at - started_at)) * 1000 AS INTEGER)) stored,
  error_code   text,
  error_message text,
  payload      jsonb,
  created_at   timestamptz default now()
);

-- Indices for performance
create index if not exists idx_az_agent_runs_agent_time
  on az_agent_runs (agent_name, started_at desc);

create index if not exists idx_az_agent_runs_status
  on az_agent_runs (status);
