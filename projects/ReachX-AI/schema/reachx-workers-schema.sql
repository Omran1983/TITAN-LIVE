-- 1) Drop old indexes and table if they exist
drop index if exists idx_workers_primary_skill;
drop index if exists idx_workers_origin_country;
drop index if exists idx_workers_preferred_destination;
drop index if exists idx_workers_source_platform;

drop table if exists public.workers;

-- 2) Enable UUID extension
create extension if not exists "uuid-ossp";

-- 3) Clean workers table definition
create table public.workers (
    id                     uuid primary key default uuid_generate_v4(),
    full_name              text not null,
    primary_skill          text not null,           -- "Chef", "Tailor", "Stone Mason", etc.
    secondary_skills       text,
    skill_category         text,                   -- "hospitality", "garment", "construction"

    experience_years       numeric(4,1),
    current_country        text,
    current_state          text,
    current_city           text,
    origin_country         text,
    preferred_destination  text,

    languages              text,
    salary_expect_min      numeric(12,2),
    salary_expect_max      numeric(12,2),
    salary_currency        text,

    availability_label     text,
    availability_date      date,

    phone                  text,
    whatsapp               text,
    email                  text,

    source_platform        text,
    source_country         text,
    source_raw_id          text,
    source_raw_url         text,

    notes                  text,

    created_at             timestamptz not null default now(),
    updated_at             timestamptz not null default now()
);

-- 4) Indexes
create index idx_workers_primary_skill
    on public.workers (lower(primary_skill));

create index idx_workers_origin_country
    on public.workers (origin_country);

create index idx_workers_preferred_destination
    on public.workers (preferred_destination);

create index idx_workers_source_platform
    on public.workers (source_platform);
