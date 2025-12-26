-- =========================================================
-- AION-ZERO FINANCIAL LEDGER (az_ledger)
-- Tracks estimated API costs per agent/operation.
-- =========================================================

create table if not exists public.az_ledger (
  id          uuid primary key default gen_random_uuid(),
  project     text not null default 'AION-ZERO',
  agent       text not null,                  -- e.g. 'code_agent', 'reflex_worker'
  operation   text not null,                  -- e.g. 'llm_generation', 'deployment'
  cost_usd    numeric(10, 6) not null default 0,
  hard_cost   jsonb default '{}'::jsonb,      -- e.g. {"tokens": 1000, "model": "gpt-4"}
  created_at  timestamptz not null default timezone('utc', now()),
  command_id  bigint                          -- optional link to az_commands.id
);

-- Index for daily budget queries
create index if not exists idx_az_ledger_project_date 
  on public.az_ledger (project, created_at);

-- View for Today's Spend
create or replace view public.az_ledger_daily_spend as
select 
  project,
  date(created_at) as log_date,
  sum(cost_usd) as total_usd,
  count(*) as op_count
from public.az_ledger
group by project, date(created_at);
