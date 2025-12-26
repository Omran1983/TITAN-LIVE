-- ==========================================================
-- ReachX Ops Schema – Agents, Contracts, Payments, Comms, Users, Audit
-- Safe to run multiple times (IF NOT EXISTS pattern)
-- ==========================================================

-- 1) Agents – internal recruiters / account managers
create table if not exists reachx_agents (
  id          uuid primary key default gen_random_uuid(),
  full_name   text not null,
  email       text,
  phone       text,
  region      text,
  role        text,           -- recruiter / sales / account_manager
  is_active   boolean not null default true,
  created_at  timestamptz default now()
);

-- 2) Contracts – commercial agreements with employers
create table if not exists reachx_contracts (
  id             bigserial primary key,
  employer_id    uuid not null references reachx_employers(id) on delete cascade,
  name           text not null,
  billing_model  text,               -- per_head / retainer / project / mixed
  rate_currency  text,
  rate_amount    numeric(18,2),
  start_date     date,
  end_date       date,
  status         text not null default 'active', -- active / expired / draft
  notes          text,
  created_at     timestamptz default now()
);

-- 3) Payments – money received against invoices
create table if not exists reachx_payments (
  id          bigserial primary key,
  invoice_id  bigint not null references reachx_employer_invoices(id) on delete cascade,
  amount      numeric(18,2) not null,
  currency    text not null default 'MUR',
  paid_at     timestamptz not null default now(),
  method      text,              -- bank, cash, card, etc
  reference   text,              -- bank ref / txn id
  created_by  uuid,              -- reachx_users.id (optional)
  created_at  timestamptz default now()
);

-- 4) Communications – calls / emails / WhatsApp / meetings
create table if not exists reachx_communications (
  id           bigserial primary key,
  employer_id  uuid references reachx_employers(id) on delete set null,
  worker_id    uuid references reachx_workers(id) on delete set null,
  request_id   bigint references reachx_requests(id) on delete set null,
  agent_id     uuid references reachx_agents(id) on delete set null,
  type         text not null,     -- call / email / whatsapp / meeting / note
  direction    text,              -- outbound / inbound
  subject      text,
  summary      text,
  channel_ref  text,              -- message id, email id, etc
  created_by   uuid,              -- reachx_users.id (optional)
  created_at   timestamptz default now()
);

-- 5) Users – application-level profiles & roles
-- We assume actual auth is handled by Supabase auth.users.
create table if not exists reachx_users (
  id            uuid primary key default gen_random_uuid(),
  auth_user_id  uuid unique,    -- references auth.users(id) logically
  email         text,
  full_name     text,
  role          text not null,  -- superadmin / admin / employer / agent / viewer
  employer_id   uuid references reachx_employers(id) on delete set null,
  is_active     boolean not null default true,
  created_at    timestamptz default now()
);

-- 6) Audit log – who did what, when
create table if not exists reachx_audit_log (
  id           bigserial primary key,
  user_id      uuid references reachx_users(id) on delete set null,
  action       text not null,      -- created / updated / deleted / login / etc
  entity_type  text not null,      -- employer / worker / request / invoice etc
  entity_id    text not null,      -- uuid or bigint as text
  details      jsonb,              -- optional detail snapshot
  created_at   timestamptz default now()
);
