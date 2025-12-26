-- =========================================================
-- EduConnect: email_log table
-- RUN THIS IN SUPABASE SQL EDITOR (project: drnqpbyptyyuacmrvdrr)
-- =========================================================

create table if not exists public.email_log (
  id            bigserial primary key,
  enrollment_id bigint references public.enrollments(id) on delete set null,
  to_email      text        not null,
  subject       text        not null,
  body          text,
  status        text        not null default 'queued',  -- queued / sent / failed
  error         text,
  created_at    timestamptz not null default now(),
  sent_at       timestamptz
);

create index if not exists idx_email_log_enrollment_id on public.email_log(enrollment_id);
create index if not exists idx_email_log_status       on public.email_log(status);

-- =========================================================
-- END
-- =========================================================
