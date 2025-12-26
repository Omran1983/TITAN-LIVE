-- PHASE 37: CITADEL BUSINESS LAYER (FINANCE + OPS + SALES)
-- Run this in Supabase SQL Editor to enable Business Mode.

-- 1. ORDERS (Finance/Sales)
create table if not exists public.orders (
  id            bigserial primary key,
  order_number  text unique,          -- e.g. "OKA-2025-000123"
  customer_id   bigint,               -- optional, if you track customers
  source        text,                 -- 'walk-in','whatsapp','website','tiktok'
  status        text not null default 'pending',   -- 'pending','paid','refunded','cancelled','void'
  total_amount  numeric(12, 2) not null default 0, -- Rs
  currency      text not null default 'MUR',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- 2. ORDER ITEMS (Product Detail)
create table if not exists public.order_items (
  id         bigserial primary key,
  order_id   bigint not null references public.orders(id) on delete cascade,
  product_id bigint,
  product_name text,
  quantity   integer not null default 1,
  unit_price numeric(12, 2) not null default 0,
  total_line numeric(12, 2) not null default 0
);

-- 3. EXPENSES (Cost Tracking)
create table if not exists public.expenses (
  id          bigserial primary key,
  category    text not null,           -- 'fuel','rent','salary','ads','misc'
  description text,
  amount      numeric(12, 2) not null,
  currency    text not null default 'MUR',
  incurred_at timestamptz not null default now(),
  related_order_id bigint              -- optional link to orders
);

-- 4. DELIVERIES (Operations)
create table if not exists public.deliveries (
  id            bigserial primary key,
  order_id      bigint references public.orders(id) on delete set null,
  client_name   text,
  address       text,
  region        text,
  driver_id     bigint,
  status        text not null default 'pending', -- 'pending','packed','dispatched','delivered','failed','cancelled'
  planned_time  timestamptz,                     -- ETA or scheduled slot
  actual_time   timestamptz,
  delay_minutes integer,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- 5. DRIVERS (Peope/Assets)
create table if not exists public.drivers (
  id          bigserial primary key,
  name        text not null,
  phone       text,
  vehicle     text,
  active      boolean not null default true,
  cost_per_day numeric(12,2) default 0
);

-- 6. ROUTES (Logistics Optimization)
create table if not exists public.routes (
  id          bigserial primary key,
  driver_id   bigint references public.drivers(id) on delete cascade,
  route_date  date not null,
  total_stops integer default 0,
  completed_stops integer default 0,
  total_distance_km numeric(12,2),
  created_at  timestamptz not null default now()
);

-- 7. CUSTOMER FEEDBACK (CX)
create table if not exists public.customer_feedback (
  id          bigserial primary key,
  customer_id bigint,
  message     text not null,
  sentiment   text, -- 'positive','negative','neutral'
  created_at  timestamptz not null default now()
);

-- Enable RLS (Optional but recommended)
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.expenses enable row level security;
alter table public.deliveries enable row level security;
alter table public.drivers enable row level security;
alter table public.routes enable row level security;
alter table public.customer_feedback enable row level security;

-- Simple RLS Policy: Allow all (since this is internal tool usage)
-- In production, you'd restrict this.
create policy "Enable all access" on public.orders for all using (true);
create policy "Enable all access" on public.order_items for all using (true);
create policy "Enable all access" on public.expenses for all using (true);
create policy "Enable all access" on public.deliveries for all using (true);
create policy "Enable all access" on public.drivers for all using (true);
create policy "Enable all access" on public.routes for all using (true);
create policy "Enable all access" on public.customer_feedback for all using (true);
