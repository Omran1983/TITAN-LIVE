-- migrations/20251219_init_decision_ledger.sql
-- TITAN Executive Decision Engine (v1 Pilot)
-- Creates: az_decision_ledger

begin;

-- Needed for gen_random_uuid()
create extension if not exists pgcrypto;

create table if not exists az_decision_ledger (
  id uuid primary key default gen_random_uuid(),

  -- core payloads
  context jsonb not null default '{}'::jsonb,  -- brief context + signals snapshot
  options jsonb not null default '[]'::jsonb,  -- candidate options presented
  decision jsonb not null default '{}'::jsonb, -- chosen option + rationale + approvals

  -- governance metadata
  "user" text not null default 'unknown',      -- executive / operator identifier
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Fast retrieval by time + user
create index if not exists idx_az_decision_ledger_created_at
  on az_decision_ledger (created_at desc);

create index if not exists idx_az_decision_ledger_user_created_at
  on az_decision_ledger ("user", created_at desc);

-- JSONB query support (optional but useful)
create index if not exists idx_az_decision_ledger_context_gin
  on az_decision_ledger using gin (context);

create index if not exists idx_az_decision_ledger_decision_gin
  on az_decision_ledger using gin (decision);

-- updated_at auto-maintenance trigger
create or replace function az_touch_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_az_decision_ledger_touch on az_decision_ledger;

create trigger trg_az_decision_ledger_touch
before update on az_decision_ledger
for each row
execute function az_touch_updated_at();

commit;
