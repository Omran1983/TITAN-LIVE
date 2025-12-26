-- TITAN V2 CORE SCHEMA: The "AZ-Native" Spine
-- Centralizes all business data into standard AZ tables.

-- 1. AZ BUSINESSES (The "Cartridges")
create table if not exists public.az_businesses (
  id            bigserial primary key,
  slug          text unique not null,
  name          text not null,
  currency      text not null default 'MUR',
  created_at    timestamptz not null default now()
);

-- 2. AZ SALES EVENTS (Universal Revenue)
create table if not exists public.az_sales_events (
  id            bigserial primary key,
  business_id   bigint references public.az_businesses(id),
  date          timestamptz not null default now(),
  amount        numeric(10,2) not null default 0,
  type          text default 'product_sale', -- product_sale, service, subscription
  source        text default 'manual',       -- manual, okasina_web, import
  customer_name text,
  notes         text,
  external_ref  text, -- e.g. "OKA-2025-001"
  created_at    timestamptz not null default now()
);

-- 3. AZ EXPENSE EVENTS (Universal Costs)
create table if not exists public.az_expense_events (
  id            bigserial primary key,
  business_id   bigint references public.az_businesses(id),
  date          timestamptz not null default now(),
  amount        numeric(10,2) not null default 0,
  category      text not null, -- rent, fuel, marketing, cogs
  vendor        text,
  notes         text,
  created_at    timestamptz not null default now()
);

-- 4. AZ CUSTOMERS (Universal CRM)
create table if not exists public.az_customers (
  id            bigserial primary key,
  business_id   bigint references public.az_businesses(id),
  name          text not null,
  phone         text,
  email         text,
  city          text,
  tags          text[],
  ltv_amount    numeric(10,2) default 0,
  last_seen     timestamptz,
  created_at    timestamptz not null default now()
);

-- 5. AZ OPS TICKETS (Universal Tasks)
create table if not exists public.az_ops_tickets (
  id            bigserial primary key,
  business_id   bigint references public.az_businesses(id),
  title         text not null,
  type          text default 'task', -- delivery_issue, complaint, task
  status        text default 'open', -- open, in_progress, done
  priority      text default 'normal',
  assigned_to   text, -- 'Omran', 'Jarvis'
  due_date      timestamptz,
  created_at    timestamptz not null default now()
);

-- 6. AZ DELIVERIES (Unified Logistics)
create table if not exists public.az_deliveries (
  id            bigserial primary key,
  business_id   bigint references public.az_businesses(id),
  ref_code      text, -- e.g. Order ID
  client_name   text,
  address       text,
  status        text default 'pending',
  driver        text,
  delivered_at  timestamptz,
  created_at    timestamptz not null default now()
);

-- 7. SEED INITIAL BUSINESSES
insert into public.az_businesses (slug, name) values 
('aogrl_deliveries', 'AOGRL Deliveries'),
('okasina', 'OKASINA Trading')
on conflict (slug) do nothing;
