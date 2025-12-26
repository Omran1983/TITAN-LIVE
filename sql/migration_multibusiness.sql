-- 1) Businesses table (multi-business support)
create table if not exists public.businesses (
  id          bigserial primary key,
  slug        text unique not null,        -- e.g. 'aogrl_deliveries', 'okasina'
  name        text not null,
  currency    text not null default 'MUR',
  timezone    text not null default 'Indian/Mauritius',
  created_at  timestamptz not null default now()
);

-- 2) Attach core tables to a business

alter table public.orders
  add column if not exists business_id bigint references public.businesses(id);

alter table public.expenses
  add column if not exists business_id bigint references public.businesses(id);

alter table public.deliveries
  add column if not exists business_id bigint references public.businesses(id);

alter table public.customer_feedback
  add column if not exists business_id bigint references public.businesses(id);

-- 3) Create first business record
insert into public.businesses (slug, name)
values ('aogrl_deliveries', 'AOGRL Deliveries')
on conflict (slug) do nothing;

-- 4) (Optional) Add second business record for future use
insert into public.businesses (slug, name)
values ('okasina', 'OKASINA Trading')
on conflict (slug) do nothing;
