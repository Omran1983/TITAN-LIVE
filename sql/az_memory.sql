-- AION-ZERO MEMORY CORE
-- Stores Chat History and User Context (Facts)

-- 1. CHAT HISTORY (The Stream of Consciousness)
create table if not exists az_chat_history (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  role text not null, -- 'user', 'assistant', 'system'
  content text not null,
  session_id text default 'default',
  metadata jsonb -- For future use (e.g. tool_calls)
);

-- 2. CONTEXT (The Knowledge Base of the User)
create table if not exists az_context (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  key text not null unique, -- e.g. 'user_name', 'project_goal'
  value text not null, -- e.g. 'Omran', 'Build AGI'
  category text default 'general', -- 'preference', 'fact', 'system'
  confidence float default 1.0
);

-- RLS POLICIES (Open for now, assumed Service Role access)
alter table az_chat_history enable row level security;
alter table az_context enable row level security;

create policy "Enable all access for service role" on az_chat_history
    as permissive for all
    to service_role
    using (true)
    with check (true);

create policy "Enable all access for service role" on az_context
    as permissive for all
    to service_role
    using (true)
    with check (true);
