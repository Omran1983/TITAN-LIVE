-- =========================================================
-- EDUCONNECT CORE SCHEMA (run once in Supabase SQL editor)
-- Project: drnqpbyptyyuacmrvdrr
-- =========================================================

-- 1) COURSES: each workshop / program you sell
create table if not exists public.courses (
  id          bigserial primary key,
  slug        text        not null unique,   -- e.g. 'ai-workshop-2025'
  title       text        not null,          -- e.g. 'AI Workshop – Level 1'
  description text,
  price_mur   numeric(12,2),
  is_active   boolean     not null default true,
  created_at  timestamptz not null default now()
);

-- 2) COURSE SESSIONS: individual dates/batches for a course
create table if not exists public.course_sessions (
  id          bigserial primary key,
  course_id   bigint      not null references public.courses(id) on delete cascade,
  name        text        not null,          -- e.g. 'Batch 01 – Dec 2025'
  start_at    timestamptz,
  end_at      timestamptz,
  location    text,
  capacity    integer,
  created_at  timestamptz not null default now()
);

-- 3) ENROLLMENTS:
-- Already created via earlier DDL; this is the reference shape.
-- ONLY run this block if your existing table is missing.
-- Otherwise, just manually ALTER to align if needed.
/*
create table if not exists public.enrollments (
  id          bigserial primary key,
  full_name   text        not null,
  email       text,
  phone       text,
  course      text,
  source      text,
  notes       text,
  status      text        not null default 'new',
  created_at  timestamptz not null default now()
);
*/

-- 4) PAYMENTS for each enrollment (manual / cash / transfer / card)
create table if not exists public.payments (
  id              bigserial primary key,
  enrollment_id   bigint      not null references public.enrollments(id) on delete cascade,
  amount_mur      numeric(12,2) not null,
  currency        text          not null default 'MUR',
  status          text          not null default 'pending',  -- pending / paid / failed / refunded
  method          text,                                     -- cash / bank_transfer / card / other
  reference       text,                                     -- receipt / bank ref / txn id
  paid_at         timestamptz,
  created_at      timestamptz not null default now()
);

-- 5) EMAIL LOG – what was sent to whom and when
create table if not exists public.email_log (
  id              bigserial primary key,
  enrollment_id   bigint references public.enrollments(id) on delete set null,
  to_email        text        not null,
  subject         text        not null,
  body            text,
  status          text        not null default 'queued',     -- queued / sent / failed
  error           text,
  created_at      timestamptz not null default now(),
  sent_at         timestamptz
);

-- 6) SMS / WHATSAPP LOG (optional, future-proof)
create table if not exists public.message_log (
  id              bigserial primary key,
  enrollment_id   bigint references public.enrollments(id) on delete set null,
  channel         text        not null,          -- sms / whatsapp / call
  to_number       text        not null,
  message         text,
  status          text        not null default 'queued',     -- queued / sent / failed
  error           text,
  provider        text,                        -- e.g. 'twilio'
  provider_ref    text,
  created_at      timestamptz not null default now(),
  sent_at         timestamptz
);

-- 7) SUMMARY VIEW – quick stats for dashboards / control center
create or replace view public.enrollment_summary as
select
  course,
  count(*)                                   as total_enrollments,
  count(*) filter (where status = 'new')     as new_enrollments,
  min(created_at)                            as first_enrollment_at,
  max(created_at)                            as latest_enrollment_at
from public.enrollments
group by course
order by latest_enrollment_at desc nulls last;

-- 8) INDEXES FOR SPEED
create index if not exists idx_enrollments_course      on public.enrollments(course);
create index if not exists idx_enrollments_created_at  on public.enrollments(created_at);
create index if not exists idx_payments_enrollment_id  on public.payments(enrollment_id);
create index if not exists idx_email_log_enrollment_id on public.email_log(enrollment_id);
create index if not exists idx_message_log_enrollment  on public.message_log(enrollment_id);

-- =========================================================
-- END OF SCHEMA
-- =========================================================
