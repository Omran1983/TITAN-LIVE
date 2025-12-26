-- schema_reachx.sql (SAFE PATCH VERSION)
-- Repairs/normalizes core ReachX tables WITHOUT dropping them.

begin;

-- Ensure UUID generator is available
create extension if not exists pgcrypto;

------------------------------------------------------------
-- EMPLOYERS  (KEEP DATA)
------------------------------------------------------------

alter table if exists reachx_employers
    add column if not exists name        text,
    add column if not exists country     text,
    add column if not exists city        text,
    add column if not exists status      text default 'active',
    add column if not exists created_at  timestamptz default now();

------------------------------------------------------------
-- DORMITORIES  (CREATE IF MISSING, ELSE PATCH)
------------------------------------------------------------

create table if not exists reachx_dormitories (
  id              bigserial primary key,
  name            text not null,
  location        text,
  capacity        integer not null default 0,
  occupied        integer not null default 0,
  created_at      timestamptz default now()
);

alter table if exists reachx_dormitories
    add column if not exists name        text,
    add column if not exists location    text,
    add column if not exists capacity    integer not null default 0,
    add column if not exists occupied    integer not null default 0,
    add column if not exists created_at  timestamptz default now();

------------------------------------------------------------
-- WORKERS  (CREATE IF MISSING, ELSE PATCH)
------------------------------------------------------------

create table if not exists reachx_workers (
  id              uuid primary key default gen_random_uuid(),
  full_name       text not null,
  passport_no     text,
  nationality     text,
  skill           text,
  status          text default 'available',
  created_at      timestamptz default now()
);

alter table if exists reachx_workers
    add column if not exists employer_id   uuid,
    add column if not exists dormitory_id  bigint,
    add column if not exists full_name     text,
    add column if not exists passport_no   text,
    add column if not exists nationality   text,
    add column if not exists skill         text,
    add column if not exists status        text default 'available',
    add column if not exists created_at    timestamptz default now();

------------------------------------------------------------
-- REQUESTS  (KEEP TABLE, JUST PATCH COLUMNS)
------------------------------------------------------------

-- We DO NOT drop reachx_requests because existing views depend on it.
-- We only ensure required columns exist.

alter table if exists reachx_requests
    add column if not exists employer_id   uuid,
    add column if not exists title         text,
    add column if not exists country       text,
    add column if not exists location      text,
    add column if not exists role          text,
    add column if not exists quantity      integer not null default 1,
    add column if not exists status        text not null default 'open',
    add column if not exists notes         text,
    add column if not exists created_at    timestamptz default now();

------------------------------------------------------------
-- ASSIGNMENTS  (CREATE IF MISSING, ELSE PATCH)
------------------------------------------------------------

create table if not exists reachx_assignments (
  id              bigserial primary key,
  request_id      bigint,
  worker_id       uuid,
  employer_id     uuid,
  status          text   not null default 'active',
  start_date      date,
  end_date        date,
  created_at      timestamptz default now()
);

alter table if exists reachx_assignments
    add column if not exists request_id    bigint,
    add column if not exists worker_id     uuid,
    add column if not exists employer_id   uuid,
    add column if not exists status        text   not null default 'active',
    add column if not exists start_date    date,
    add column if not exists end_date      date,
    add column if not exists created_at    timestamptz default now();

------------------------------------------------------------
-- EMPLOYER INVOICES  (CREATE IF MISSING, ELSE PATCH)
------------------------------------------------------------

create table if not exists reachx_employer_invoices (
  id              bigserial primary key,
  employer_id     uuid,
  assignment_id   bigint,
  invoice_no      text   not null,
  amount          numeric(12,2) not null,
  currency        text   not null default 'MUR',
  status          text   not null default 'unpaid',
  issued_at       timestamptz default now(),
  due_at          timestamptz
);

alter table if exists reachx_employer_invoices
    add column if not exists employer_id   uuid,
    add column if not exists assignment_id bigint,
    add column if not exists invoice_no    text,
    add column if not exists amount        numeric(12,2),
    add column if not exists currency      text   not null default 'MUR',
    add column if not exists status        text   not null default 'unpaid',
    add column if not exists issued_at     timestamptz default now(),
    add column if not exists due_at        timestamptz;

------------------------------------------------------------
-- EMPLOYER SUMMARY VIEW (SAFE REBUILD)
------------------------------------------------------------

drop view if exists reachx_employer_invoices_view;

create or replace view reachx_employer_invoices_view as
select
    e.id                                        as employer_id,
    e.name                                      as employer_name,
    e.country                                   as country,
    e.city                                      as city,
    e.status                                    as employer_status,
    count(distinct r.id)                        as total_requests,
    count(distinct r.id) filter (where r.status = 'open') as open_requests,
    count(distinct a.id) filter (where a.status = 'active') as active_assignments,
    coalesce(
        sum(i.amount) filter (where i.status = 'unpaid'),
        0
    )                                           as unpaid_amount
from reachx_employers e
left join reachx_requests r
       on r.employer_id = e.id
left join reachx_assignments a
       on a.employer_id = e.id
left join reachx_employer_invoices i
       on i.employer_id = e.id
group by
    e.id,
    e.name,
    e.country,
    e.city,
    e.status;

commit;
