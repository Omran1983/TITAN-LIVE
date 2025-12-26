-- TITAN UPTIME MONITOR SCHEMA
-- Purpose: Track website availability and latency for paid reporting.

-- 1. TARGETS (The websites we watch)
create table if not exists public.az_uptime_targets (
    id              bigserial primary key,
    name            text not null,              -- Client Name or Site Name
    url             text not null,              -- The URL to monitor
    contact_email   text,                       -- Extracted Support Email
    check_interval  int default 60,             -- Frequency in minutes
    is_active       boolean default true,
    created_at      timestamptz default now()
);

-- 2. EVENTS (The log of "pings")
create table if not exists public.az_uptime_events (
    id              bigserial primary key,
    target_id       bigint references public.az_uptime_targets(id),
    status_code     int,                        -- 200, 404, 500
    latency_ms      int,                        -- Response time
    is_up           boolean,                    -- True if 200-299
    error_msg       text,                       -- DNS error, timeout, etc.
    timestamp       timestamptz default now()
);

-- 3. OUTREACH QUEUE (The Human Filter)
create table if not exists public.az_outreach_queue (
    id              bigserial primary key,
    target_id       bigint references public.az_uptime_targets(id),
    channel         text default 'email',       -- email, whatsapp
    recipient       text not null,
    subject         text,
    body            text,
    status          text default 'draft',       -- draft, approved, sent, rejected
    created_at      timestamptz default now(),
    sent_at         timestamptz
);

-- Seed some Demo Targets (You can sell these reports immediately)
insert into public.az_uptime_targets (name, url) values 
('Example Global', 'https://www.example.com'),
('Google Public', 'https://www.google.com')
on conflict do nothing;
