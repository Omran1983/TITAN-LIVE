-- 001_governance_v2.sql

create extension if not exists pgcrypto;

drop table if exists az_intents;
drop table if exists az_audit_log;

create table az_intents (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by text not null default 'ui',
  agent_name text,
  ui_intent text not null,               -- e.g. "console_command"
  proposed_action text not null,         -- e.g. "tools.restart"
  proposed_args jsonb not null default '{}'::jsonb,
  confidence float,
  risk_level text not null,              -- L0-L4
  explanation text,
  status text not null default 'PENDING',-- PENDING|APPROVED|REJECTED|EXECUTED
  decision_metadata jsonb not null default '{}'::jsonb
);

create index az_intents_status_idx on az_intents(status);
create index az_intents_created_at_idx on az_intents(created_at desc);

create table az_audit_log (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  actor text not null,                   -- user/token subject
  action text not null,                  -- action key
  intent_id uuid,
  authority_required text,
  authority_granted text,
  risk_level text,
  status text not null,                  -- OK|DENY|ERROR
  request jsonb not null default '{}'::jsonb,
  result jsonb not null default '{}'::jsonb,
  error text
);

create index az_audit_log_created_at_idx on az_audit_log(created_at desc);
create index az_audit_log_action_idx on az_audit_log(action);
create index az_audit_log_intent_idx on az_audit_log(intent_id);
