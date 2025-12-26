-- =========================================================
-- REGRESSION / PERFORMANCE / BUSINESS KPI SCHEMA PACK v1
-- =========================================================

-- 1) Regression runs (internal Jarvis test tracking)
create table if not exists public.az_regression_runs (
  id          bigserial primary key,
  project     text not null default 'aion_zero',
  suite       text not null default 'default',
  status      text not null,                  -- passed / failed / error / running
  passed      integer not null default 0,
  failed      integer not null default 0,
  duration_ms integer,
  created_at  timestamptz not null default timezone('utc', now()),
  meta        jsonb default '{}'::jsonb
);

create or replace view public.az_cc_regression_latest as
select distinct on (suite)
  suite,
  status,
  passed,
  failed,
  duration_ms,
  created_at,
  meta
from public.az_regression_runs
order by suite, created_at desc;


-- 2) Performance checks (endpoint / job health & latency)
create table if not exists public.az_performance_checks (
  id          bigserial primary key,
  project     text not null default 'aion_zero',
  target      text not null,                  -- e.g. 'commands_api', 'notify_worker'
  metric      text not null,                  -- e.g. 'latency_ms', 'error_rate'
  value       numeric,
  threshold   numeric,
  status      text not null,                  -- ok / warning / critical
  created_at  timestamptz not null default timezone('utc', now()),
  meta        jsonb default '{}'::jsonb
);

create or replace view public.az_cc_performance_latest as
select distinct on (target, metric)
  target,
  metric,
  value,
  threshold,
  status,
  created_at,
  meta
from public.az_performance_checks
order by target, metric, created_at desc;


-- 3) Business KPIs (high-level AOGRL dashboard)
create table if not exists public.az_business_kpis (
  id          bigserial primary key,
  project     text not null default 'aion_zero',
  kpi_key     text not null,                  -- e.g. 'mrr', 'active_clients'
  kpi_label   text not null,                  -- human readable
  value       numeric,
  target      numeric,
  unit        text,                           -- 'MUR', '%', 'agents'
  period      text,                           -- 'daily', 'weekly', 'monthly'
  status      text,                           -- on_track / off_track / unknown
  created_at  timestamptz not null default timezone('utc', now()),
  meta        jsonb default '{}'::jsonb
);

create or replace view public.az_cc_business_kpis_latest as
select distinct on (kpi_key)
  kpi_key,
  kpi_label,
  value,
  target,
  unit,
  period,
  status,
  created_at,
  meta
from public.az_business_kpis
order by kpi_key, created_at desc;
