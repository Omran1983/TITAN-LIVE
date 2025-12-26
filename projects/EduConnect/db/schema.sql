-- =========================
-- EduConnect MVP Schema
-- =========================

-- Extensions
create extension if not exists "pgcrypto";

-- ---------- Helpers ----------
create or replace function public.is_org_member(p_org uuid)
returns boolean
language sql stable
as $$
  select exists (
    select 1 from public.org_members m
    where m.org_id = p_org and m.user_id = auth.uid()
  );
$$;

create or replace function public.is_org_admin(p_org uuid)
returns boolean
language sql stable
as $$
  select exists (
    select 1 from public.org_members m
    where m.org_id = p_org and m.user_id = auth.uid()
      and m.role in ('owner','admin')
  );
$$;

-- ---------- Core identity ----------
create table if not exists public.organizations (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  owner_id   uuid not null,
  created_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id         uuid primary key, -- = auth.users.id
  full_name  text,
  org_id     uuid references public.organizations(id) on delete set null,
  role       text check (role in ('owner','admin','staff','student')) default 'student',
  avatar_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.org_members (
  org_id     uuid not null references public.organizations(id) on delete cascade,
  user_id    uuid not null,
  role       text not null check (role in ('owner','admin','staff','student')),
  created_at timestamptz not null default now(),
  primary key (org_id, user_id)
);

create index if not exists idx_org_members_user on public.org_members(user_id);

-- ---------- Learning model ----------
create table if not exists public.courses (
  id         uuid primary key default gen_random_uuid(),
  org_id     uuid not null references public.organizations(id) on delete cascade,
  title      text not null,
  slug       text unique,
  status     text not null default 'draft' check (status in ('draft','live','archived')),
  created_at timestamptz not null default now()
);
create index if not exists idx_courses_org_status on public.courses(org_id, status);

create table if not exists public.lessons (
  id         uuid primary key default gen_random_uuid(),
  course_id  uuid not null references public.courses(id) on delete cascade,
  title      text not null,
  content_url text,
  order_no   int default 0,
  created_at timestamptz not null default now()
);
create index if not exists idx_lessons_course_order on public.lessons(course_id, order_no);

create table if not exists public.enrollments (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null,
  course_id  uuid not null references public.courses(id) on delete cascade,
  status     text not null default 'active' check (status in ('active','completed','dropped')),
  created_at timestamptz not null default now(),
  unique (user_id, course_id)
);

create table if not exists public.assignments (
  id         uuid primary key default gen_random_uuid(),
  course_id  uuid not null references public.courses(id) on delete cascade,
  title      text not null,
  due_at     timestamptz,
  points     int default 100,
  created_at timestamptz not null default now()
);

create table if not exists public.submissions (
  id          uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references public.assignments(id) on delete cascade,
  user_id     uuid not null,
  file_url    text,
  grade       numeric,
  feedback    text,
  created_at  timestamptz not null default now()
);
create index if not exists idx_submissions_assignment_user on public.submissions(assignment_id, user_id);

-- ---------- Ops / delivery ----------
create table if not exists public.tasks (
  id          uuid primary key default gen_random_uuid(),
  org_id      uuid not null references public.organizations(id) on delete cascade,
  title       text not null,
  status      text not null default 'todo' check (status in ('todo','doing','done','blocked')),
  assignee_id uuid,
  due_at      timestamptz,
  tags        text[],
  created_at  timestamptz not null default now()
);
create index if not exists idx_tasks_org_status on public.tasks(org_id, status, assignee_id);

create table if not exists public.messages (
  id         uuid primary key default gen_random_uuid(),
  org_id     uuid not null references public.organizations(id) on delete cascade,
  channel    text not null,
  sender_id  uuid not null,
  text       text not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_messages_org_channel_time on public.messages(org_id, channel, created_at desc);

create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null,
  kind       text not null,
  payload    jsonb,
  read_at    timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists idx_notifications_user_read on public.notifications(user_id, read_at);

-- ---------- Commerce (stub) ----------
create table if not exists public.orders (
  id         uuid primary key default gen_random_uuid(),
  org_id     uuid not null references public.organizations(id) on delete cascade,
  user_id    uuid,
  amount     numeric(12,2) not null default 0,
  currency   text not null default 'MUR',
  status     text not null default 'pending' check (status in ('pending','paid','failed','refunded')),
  meta       jsonb,
  created_at timestamptz not null default now()
);
create index if not exists idx_orders_org_status_time on public.orders(org_id, status, created_at desc);

-- ---------- Telemetry ----------
create table if not exists public.project_events (
  id         bigserial primary key,
  kind       text,
  title      text,
  meta       jsonb,
  created_at timestamptz not null default now()
);
create index if not exists idx_project_events_time on public.project_events(created_at desc);

create table if not exists public.errors (
  id         bigserial primary key,
  source     text,
  level      text check (level in ('warn','error')),
  message    text,
  context    jsonb,
  created_at timestamptz not null default now()
);
create index if not exists idx_errors_time on public.errors(created_at desc);

-- ---------- RLS ----------
alter table public.organizations enable row level security;
alter table public.profiles      enable row level security;
alter table public.org_members   enable row level security;
alter table public.courses       enable row level security;
alter table public.lessons       enable row level security;
alter table public.enrollments   enable row level security;
alter table public.assignments   enable row level security;
alter table public.submissions   enable row level security;
alter table public.tasks         enable row level security;
alter table public.messages      enable row level security;
alter table public.notifications enable row level security;
alter table public.orders        enable row level security;
alter table public.project_events enable row level security;
alter table public.errors         enable row level security;

-- Organizations: members can read; owner/admin can write
drop policy if exists org_select on public.organizations;
create policy org_select on public.organizations
  for select using (is_org_member(id));

drop policy if exists org_write on public.organizations;
create policy org_write on public.organizations
  for all to authenticated
  using (is_org_admin(id)) with check (is_org_admin(id));

-- Profiles: user reads/updates own; org admins read all in org
drop policy if exists profiles_self on public.profiles;
create policy profiles_self on public.profiles
  for select using (auth.uid() = id);

drop policy if exists profiles_self_upd on public.profiles;
create policy profiles_self_upd on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists profiles_admin_view on public.profiles;
create policy profiles_admin_view on public.profiles
  for select to authenticated
  using (exists (select 1 from public.org_members m where m.org_id = profiles.org_id and m.user_id = auth.uid() and m.role in ('owner','admin')));

-- Org members: user sees own membership; admin writes
drop policy if exists om_self on public.org_members;
create policy om_self on public.org_members
  for select using (user_id = auth.uid());

drop policy if exists om_admin on public.org_members;
create policy om_admin on public.org_members
  for all to authenticated
  using (is_org_admin(org_id)) with check (is_org_admin(org_id));

-- Generic org-scoped tables policy helper (read/write for members)
-- Courses
drop policy if exists courses_rw on public.courses;
create policy courses_rw on public.courses
  for all to authenticated
  using (is_org_member(org_id)) with check (is_org_member(org_id));

-- Lessons
drop policy if exists lessons_rw on public.lessons;
create policy lessons_rw on public.lessons
  for all to authenticated
  using (exists (select 1 from public.courses c where c.id = lessons.course_id and is_org_member(c.org_id)))
  with check (exists (select 1 from public.courses c where c.id = lessons.course_id and is_org_member(c.org_id)));

-- Enrollments
drop policy if exists enrollments_rw on public.enrollments;
create policy enrollments_rw on public.enrollments
  for all to authenticated
  using (exists (select 1 from public.courses c where c.id = enrollments.course_id and is_org_member(c.org_id)))
  with check (exists (select 1 from public.courses c where c.id = enrollments.course_id and is_org_member(c.org_id)));

-- Assignments / Submissions
drop policy if exists assignments_rw on public.assignments;
create policy assignments_rw on public.assignments
  for all to authenticated
  using (exists (select 1 from public.courses c where c.id = assignments.course_id and is_org_member(c.org_id)))
  with check (exists (select 1 from public.courses c where c.id = assignments.course_id and is_org_member(c.org_id)));

drop policy if exists submissions_rw on public.submissions;
create policy submissions_rw on public.submissions
  for all to authenticated
  using (true) with check (true);

-- Tasks
drop policy if exists tasks_rw on public.tasks;
create policy tasks_rw on public.tasks
  for all to authenticated
  using (is_org_member(org_id)) with check (is_org_member(org_id));

-- Messages
drop policy if exists messages_rw on public.messages;
create policy messages_rw on public.messages
  for all to authenticated
  using (is_org_member(org_id)) with check (is_org_member(org_id));

-- Notifications (own only)
drop policy if exists notifications_self on public.notifications;
create policy notifications_self on public.notifications
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Orders
drop policy if exists orders_rw on public.orders;
create policy orders_rw on public.orders
  for all to authenticated
  using (is_org_member(org_id)) with check (is_org_member(org_id));

-- Telemetry (service role writes; admins read)
drop policy if exists pe_read on public.project_events;
create policy pe_read on public.project_events
  for select to authenticated using (true);

drop policy if exists err_read on public.errors;
create policy err_read on public.errors
  for select to authenticated using (true);

-- ---------- Reporting RPC ----------
create or replace function public.daily_summary()
returns table(
  now timestamptz,
  tasks bigint,
  users bigint,
  errors bigint,
  orders bigint,
  tasks_24h bigint,
  errors_24h bigint,
  orders_24h bigint
) language plpgsql stable security definer
set search_path = public
as $$
declare
  cutoff timestamptz := now() - interval '24 hours';
begin
  return query
  select
    now() as now,
    coalesce((select count(*) from public.tasks),0) as tasks,
    coalesce((select count(*) from public.profiles),0) as users,
    coalesce((select count(*) from public.errors),0) as errors,
    coalesce((select count(*) from public.orders),0) as orders,
    coalesce((select count(*) from public.tasks  where created_at >= cutoff),0) as tasks_24h,
    coalesce((select count(*) from public.errors where created_at >= cutoff),0) as errors_24h,
    coalesce((select count(*) from public.orders where created_at >= cutoff),0) as orders_24h;
end$$;

grant execute on function public.daily_summary() to anon, authenticated;