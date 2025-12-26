-- Optional: projects registry (v3.1)
create table if not exists public.az_projects (
  project_id text primary key,
  display_name text not null,
  description text not null default '',
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists az_projects_enabled_idx on public.az_projects(enabled, project_id);

-- updated_at trigger reuse
drop trigger if exists trg_az_projects_touch on public.az_projects;
create trigger trg_az_projects_touch
before update on public.az_projects
for each row execute function public.az_touch_updated_at();

-- seed a few defaults (safe upsert)
insert into public.az_projects(project_id, display_name, description, enabled)
values
  ('titan_smoke','TITAN Smoke Check','Quick environment check (python/node/git).',true),
  ('titan_inspect','TITAN Inspector','Runs your inspector workflow.',true),
  ('titan_deploy_local','TITAN Deploy (Local)','Pull + build from your TITAN root.',true)
on conflict (project_id) do update
set display_name = excluded.display_name,
    description = excluded.description,
    enabled = excluded.enabled,
    updated_at = now();
